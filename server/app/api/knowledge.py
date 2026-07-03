import logging
import re
import uuid
from datetime import datetime, timezone
from pathlib import Path

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, UploadFile

from app.core.config import settings
from app.core.logging import log_agent_event
from app.schemas.knowledge import (
    KnowledgeDocument,
    KnowledgeListResponse,
    KnowledgeUploadResponse,
    UploadedBy,
)
from app.rag.ingestion import (
    chunk_text,
    embed_batch,
    insert_chunks,
    parse_file,
    update_document_status,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/knowledge", tags=["knowledge"])

ALLOWED_EXTS = {"pdf", "docx", "txt", "md"}
_FILENAME_SANITIZE_RE = re.compile(r"[^a-zA-Z0-9._-]")


async def _get_allowed_user():
    return {"user_id": "dev_user", "name": "Developer", "role": "admin"}


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
    name = name.replace("..", "").replace("/", "_").replace("\\", "_")
    return _FILENAME_SANITIZE_RE.sub("_", name)


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
    current_user: dict = Depends(_get_allowed_user),
):
    if current_user.get("role") not in ("pengajar", "admin", "developer"):
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

    document_id = f"kd_{uuid.uuid4()}"
    sanitized_name = _sanitize_filename(file.filename or "file")
    upload_path = Path(settings.UPLOAD_DIR) / document_id / sanitized_name
    upload_path.parent.mkdir(parents=True, exist_ok=True)
    upload_path.write_bytes(content)

    doc_title = (title or _strip_ext(file.filename or "file"))[:200]
    tag_list = [t.strip() for t in (tags or "").split(",") if t.strip()]

    import asyncpg
    dsn = settings.DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")
    conn = await asyncpg.connect(dsn=dsn, timeout=5)
    try:
        await conn.execute(
            """
            INSERT INTO knowledge_documents (id, file_name, file_type, file_size_bytes,
                                              title, author, description, tags,
                                              uploaded_by, status)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'processing')
            """,
            uuid.UUID(document_id.replace("kd_", "")),
            file.filename or "file",
            ext,
            len(content),
            doc_title,
            author[:100] if author else None,
            description[:500] if description else None,
            tag_list,
            uuid.UUID(current_user["user_id"]),
        )
    finally:
        await conn.close()

    background_tasks.add_task(_ingest_document, document_id, upload_path, ext)

    log_agent_event("knowledge_upload", document_id=document_id, file_type=ext, file_size=len(content))

    return KnowledgeUploadResponse(
        document_id=document_id,
        file_name=file.filename or "file",
        file_type=ext,
        file_size_bytes=len(content),
        title=doc_title,
        status="processing",
        message="File diterima, sedang diproses (chunking + embedding). Cek status via GET /api/v1/knowledge/{document_id}",
        created_at=datetime.now(timezone.utc),
    )


async def _ingest_document(document_id: str, file_path: Path, ext: str) -> None:
    raw_doc_id = document_id.replace("kd_", "")
    try:
        text = await parse_file(file_path, ext)
        if not text.strip():
            await update_document_status(raw_doc_id, "failed", error_message="File kosong atau tidak bisa dibaca.")
            return

        chunks = chunk_text(text)
        if not chunks:
            await update_document_status(raw_doc_id, "failed", error_message="Tidak ada konten yang bisa diproses.")
            return

        chunk_contents = [c["content"] for c in chunks]
        embeddings = await embed_batch(chunk_contents)
        await insert_chunks(raw_doc_id, chunks, embeddings)
        await update_document_status(raw_doc_id, "ready", total_chunks=len(chunks))

        logger.info("Ingestion complete: doc=%s chunks=%d", document_id, len(chunks))
    except Exception as e:
        logger.exception("Ingestion failed: doc=%s", document_id)
        await update_document_status(raw_doc_id, "failed", error_message=_humanize_error(e))


@router.get("/{document_id}", response_model=KnowledgeDocument)
async def get_document(document_id: str):
    import asyncpg
    dsn = settings.DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")
    conn = await asyncpg.connect(dsn=dsn, timeout=5)
    try:
        row = await conn.fetchrow(
            """
            SELECT id, file_name, file_type, file_size_bytes,
                   title, author, description, tags,
                   total_chunks, status, error_message,
                   uploaded_by, created_at, processed_at
            FROM knowledge_documents WHERE id = $1
            """,
            uuid.UUID(document_id.replace("kd_", "")),
        )
    finally:
        await conn.close()

    if not row:
        raise HTTPException(404, "Dokumen tidak ditemukan")

    return KnowledgeDocument(
        document_id=f"kd_{row['id']}",
        file_name=row["file_name"],
        file_type=row["file_type"],
        file_size_bytes=row["file_size_bytes"],
        title=row["title"],
        author=row.get("author"),
        description=row.get("description"),
        tags=list(row.get("tags") or []),
        total_chunks=row["total_chunks"],
        status=row["status"],
        error_message=row.get("error_message"),
        uploaded_by=UploadedBy(user_id=str(row["uploaded_by"]), name=""),
        created_at=row["created_at"],
        processed_at=row.get("processed_at"),
    )


@router.get("", response_model=KnowledgeListResponse)
async def list_documents(
    page: int = 1,
    page_size: int = 20,
    status: str | None = None,
    search: str | None = None,
):
    import asyncpg
    dsn = settings.DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")
    conn = await asyncpg.connect(dsn=dsn, timeout=5)
    try:
        conditions: list[str] = []
        params: list = []
        param_idx = 0

        if status:
            param_idx += 1
            conditions.append(f"status = ${param_idx}")
            params.append(status)
        if search:
            param_idx += 1
            conditions.append(f"(title ILIKE ${param_idx} OR file_name ILIKE ${param_idx})")
            params.append(f"%{search}%")

        where = " WHERE " + " AND ".join(conditions) if conditions else ""

        count_row = await conn.fetchval(f"SELECT COUNT(*) FROM knowledge_documents{where}", *params)
        total = count_row or 0

        offset = (page - 1) * page_size
        rows = await conn.fetch(
            f"""
            SELECT id, file_name, file_type, file_size_bytes,
                   title, author, description, tags,
                   total_chunks, status, error_message,
                   uploaded_by, created_at, processed_at
            FROM knowledge_documents{where}
            ORDER BY created_at DESC
            LIMIT ${param_idx + 1} OFFSET ${param_idx + 2}
            """,
            *params, page_size, offset,
        )
    finally:
        await conn.close()

    items = [
        KnowledgeDocument(
            document_id=f"kd_{row['id']}",
            file_name=row["file_name"],
            file_type=row["file_type"],
            file_size_bytes=row["file_size_bytes"],
            title=row["title"],
            author=row.get("author"),
            description=row.get("description"),
            tags=list(row.get("tags") or []),
            total_chunks=row["total_chunks"],
            status=row["status"],
            error_message=row.get("error_message"),
            uploaded_by=UploadedBy(user_id=str(row["uploaded_by"]), name=""),
            created_at=row["created_at"],
            processed_at=row.get("processed_at"),
        )
        for row in rows
    ]

    return KnowledgeListResponse(items=items, total=total, page=page, page_size=page_size)


@router.delete("/{document_id}", status_code=204)
async def delete_document(document_id: str):
    import asyncpg
    dsn = settings.DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")
    conn = await asyncpg.connect(dsn=dsn, timeout=5)
    try:
        result = await conn.execute(
            "DELETE FROM knowledge_documents WHERE id = $1",
            uuid.UUID(document_id.replace("kd_", "")),
        )
    finally:
        await conn.close()

    if result == "DELETE 0":
        raise HTTPException(404, "Dokumen tidak ditemukan")

    file_path = Path(settings.UPLOAD_DIR) / document_id
    if file_path.exists():
        import shutil
        shutil.rmtree(file_path)
        logger.info("Deleted upload directory: %s", file_path)

    log_agent_event("knowledge_delete", document_id=document_id)
