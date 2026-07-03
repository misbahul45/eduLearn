import logging
import re
import uuid
from datetime import datetime, timezone
from pathlib import Path

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, UploadFile
from sqlalchemy import func, select, text
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.core.config import settings
from app.core.logging import log_agent_event
from app.db.models import KnowledgeDocument as KnowledgeDocumentModel
from app.db.models import KnowledgeChunk, User
from app.rag.ingestion import chunk_text, embed_batch, parse_file
from app.schemas.knowledge import (
    KnowledgeDocument,
    KnowledgeListResponse,
    KnowledgeUploadResponse,
    UploadedBy,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/knowledge", tags=["knowledge"])

ALLOWED_EXTS = {"pdf", "docx", "txt", "md"}
_FILENAME_SANITIZE_RE = re.compile(r"[^a-zA-Z0-9._-]")


def _validate_magic_number(content: bytes, ext: str) -> bool:
    if ext == "pdf":
        return content[:5] == b"%PDF-"
    if ext == "docx":
        return content[:2] == b"PK"
    if ext in ("txt", "md"):
        try:
            content.decode("utf-8")
            return True
        except UnicodeDecodeError:
            return False
    return False


def _sanitize_filename(name: str) -> str:
    return _FILENAME_SANITIZE_RE.sub("_", name.replace("..", "").replace("/", "_").replace("\\", "_"))


def _strip_ext(name: str) -> str:
    return name.rsplit(".", 1)[0] if "." in name else name


def _humanize_error(exc: Exception) -> str:
    msg = str(exc)
    if "embedding" in msg.lower():
        return "Layanan embedding sedang bermasalah, coba upload ulang nanti."
    if "timeout" in msg.lower() or "timed out" in msg.lower():
        return "Waktu proses habis. File terlalu besar atau kompleks."
    return f"Gagal memproses file. {msg[:200]}"


@router.post("/upload", response_model=KnowledgeUploadResponse, status_code=201)
async def upload_knowledge(
    background_tasks: BackgroundTasks,
    file: UploadFile,
    title: str | None = None,
    author: str | None = None,
    description: str | None = None,
    tags: str | None = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if current_user.role not in ("pengajar", "admin"):
        raise HTTPException(403, "Hanya pengajar/admin yang boleh upload materi")

    ext = file.filename.rsplit(".", 1)[-1].lower() if "." in (file.filename or "") else ""
    if ext not in ALLOWED_EXTS:
        raise HTTPException(
            400,
            f"Ekstensi file .{ext} tidak diizinkan. Allowed: {', '.join(sorted(ALLOWED_EXTS))}",
        )

    content = await file.read()
    max_bytes = settings.UPLOAD_MAX_FILE_SIZE_MB * 1024 * 1024
    if len(content) > max_bytes:
        raise HTTPException(413, f"Ukuran file melebihi batas {settings.UPLOAD_MAX_FILE_SIZE_MB}MB")

    if not _validate_magic_number(content, ext):
        raise HTTPException(400, "Konten file tidak sesuai dengan ekstensi (kemungkinan spoofing)")

    doc_id = uuid.uuid4()
    sanitized_name = _sanitize_filename(file.filename or "file")
    upload_path = Path(settings.UPLOAD_DIR) / str(doc_id) / sanitized_name
    upload_path.parent.mkdir(parents=True, exist_ok=True)
    upload_path.write_bytes(content)

    doc_title = (title or _strip_ext(file.filename or "file"))[:200]
    tag_list = [t.strip() for t in (tags or "").split(",") if t.strip()]

    doc = KnowledgeDocumentModel(
        id=doc_id,
        file_name=file.filename or "file",
        file_type=ext,
        file_size_bytes=len(content),
        title=doc_title,
        author=(author or "")[:200] if author else None,
        description=(description or "")[:500] if description else None,
        tags=tag_list,
        uploaded_by=current_user.id,
        status="processing",
    )
    db.add(doc)
    await db.flush()

    background_tasks.add_task(_ingest_document, str(doc_id), upload_path, ext)

    log_agent_event("knowledge_upload", document_id=str(doc_id), file_type=ext, file_size=len(content))

    return KnowledgeUploadResponse(
        document_id=str(doc_id),
        file_name=file.filename or "file",
        file_type=ext,
        file_size_bytes=len(content),
        title=doc_title,
        status="processing",
        message="File diterima, sedang diproses (chunking + embedding). Cek status via GET /api/v1/knowledge/{document_id}",
        created_at=datetime.now(timezone.utc),
    )


async def _ingest_document(doc_id_str: str, file_path: Path, ext: str) -> None:
    from app.db import async_session_maker

    async with async_session_maker() as session:
        try:
            text_content = await parse_file(file_path, ext)
            if not text_content.strip():
                await _update_doc_status(session, doc_id_str, "failed", error_message="File kosong atau tidak bisa dibaca.")
                return

            chunks = chunk_text(text_content)
            if not chunks:
                await _update_doc_status(session, doc_id_str, "failed", error_message="Tidak ada konten yang bisa diproses.")
                return

            chunk_contents = [c["content"] for c in chunks]
            embeddings = await embed_batch(chunk_contents)

            for chunk, embedding in zip(chunks, embeddings):
                chunk_id = uuid.uuid4()
                await session.execute(
                    text("""
                        INSERT INTO knowledge_chunks (id, document_id, chunk_index, content, embedding, extra_metadata)
                        VALUES (:id, :doc_id, :idx, :content, :emb::vector, :meta)
                    """),
                    {
                        "id": chunk_id,
                        "doc_id": uuid.UUID(doc_id_str),
                        "idx": chunk["chunk_index"],
                        "content": chunk["content"],
                        "emb": embedding,
                        "meta": chunk.get("metadata", {}),
                    },
                )

            await _update_doc_status(session, doc_id_str, "ready", total_chunks=len(chunks))
            logger.info("Ingestion complete: doc=%s chunks=%d", doc_id_str, len(chunks))
        except Exception as e:
            logger.exception("Ingestion failed: doc=%s", doc_id_str)
            await _update_doc_status(session, doc_id_str, "failed", error_message=_humanize_error(e))
        finally:
            await session.commit()


async def _update_doc_status(
    session: AsyncSession,
    document_id: str,
    status: str,
    total_chunks: int | None = None,
    error_message: str | None = None,
) -> None:
    doc_id = uuid.UUID(document_id)
    if status == "ready" and total_chunks is not None:
        await session.execute(
            text("UPDATE knowledge_documents SET status = :status, total_chunks = :total_chunks, processed_at = NOW() WHERE id = :id"),
            {"status": status, "total_chunks": total_chunks, "id": doc_id},
        )
    elif status == "failed":
        await session.execute(
            text("UPDATE knowledge_documents SET status = :status, error_message = :error WHERE id = :id"),
            {"status": status, "error": error_message, "id": doc_id},
        )
    else:
        await session.execute(
            text("UPDATE knowledge_documents SET status = :status WHERE id = :id"),
            {"status": status, "id": doc_id},
        )


@router.get("/{document_id}", response_model=KnowledgeDocument)
async def get_document(
    document_id: str,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(KnowledgeDocumentModel).where(KnowledgeDocumentModel.id == uuid.UUID(document_id))
    )
    doc = result.scalar_one_or_none()
    if not doc:
        raise HTTPException(404, "Dokumen tidak ditemukan")

    return KnowledgeDocument(
        document_id=str(doc.id),
        file_name=doc.file_name,
        file_type=doc.file_type,
        file_size_bytes=doc.file_size_bytes,
        title=doc.title,
        author=doc.author,
        description=doc.description,
        tags=doc.tags or [],
        total_chunks=doc.total_chunks,
        status=doc.status,
        error_message=doc.error_message,
        uploaded_by=UploadedBy(user_id=str(doc.uploaded_by), name=""),
        created_at=doc.created_at,
        processed_at=doc.processed_at,
    )


@router.get("", response_model=KnowledgeListResponse)
async def list_documents(
    page: int = 1,
    page_size: int = 20,
    status: str | None = None,
    search: str | None = None,
    db: AsyncSession = Depends(get_db),
):
    query = select(KnowledgeDocumentModel)
    count_query = select(func.count(KnowledgeDocumentModel.id))

    if status:
        query = query.where(KnowledgeDocumentModel.status == status)
        count_query = count_query.where(KnowledgeDocumentModel.status == status)
    if search:
        pattern = f"%{search}%"
        filter_cond = KnowledgeDocumentModel.title.ilike(pattern) | KnowledgeDocumentModel.file_name.ilike(pattern)
        query = query.where(filter_cond)
        count_query = count_query.where(filter_cond)

    total = await db.scalar(count_query) or 0
    offset = (page - 1) * page_size
    result = await db.execute(
        query.order_by(KnowledgeDocumentModel.created_at.desc()).offset(offset).limit(page_size)
    )

    items = [
        KnowledgeDocument(
            document_id=str(doc.id),
            file_name=doc.file_name,
            file_type=doc.file_type,
            file_size_bytes=doc.file_size_bytes,
            title=doc.title,
            author=doc.author,
            description=doc.description,
            tags=doc.tags or [],
            total_chunks=doc.total_chunks,
            status=doc.status,
            error_message=doc.error_message,
            uploaded_by=UploadedBy(user_id=str(doc.uploaded_by), name=""),
            created_at=doc.created_at,
            processed_at=doc.processed_at,
        )
        for doc in result.scalars().all()
    ]

    return KnowledgeListResponse(items=items, total=total or 0, page=page, page_size=page_size)


@router.delete("/{document_id}", status_code=204)
async def delete_document(
    document_id: str,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(KnowledgeDocumentModel).where(KnowledgeDocumentModel.id == uuid.UUID(document_id))
    )
    doc = result.scalar_one_or_none()
    if not doc:
        raise HTTPException(404, "Dokumen tidak ditemukan")

    await db.delete(doc)

    dir_path = Path(settings.UPLOAD_DIR) / document_id
    if dir_path.exists():
        import shutil
        shutil.rmtree(dir_path)
        logger.info("Deleted upload directory: %s", dir_path)

    log_agent_event("knowledge_delete", document_id=document_id)
