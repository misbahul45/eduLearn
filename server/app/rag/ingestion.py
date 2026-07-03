import logging
import re
import uuid
from pathlib import Path
from typing import Any

logger = logging.getLogger(__name__)

HEADING_RE = re.compile(r"^(#{1,6}\s|[-*]{3,}$)", re.MULTILINE)


async def parse_file(file_path: Path, ext: str) -> str:
    if ext == "pdf":
        return _parse_pdf(file_path)
    if ext == "docx":
        return _parse_docx(file_path)
    if ext in ("txt", "md"):
        return file_path.read_text(encoding="utf-8")
    msg = f"Unsupported file type: {ext}"
    raise ValueError(msg)


def _parse_pdf(file_path: Path) -> str:
    try:
        import fitz
    except ImportError:
        raise ImportError("pymupdf not installed")
    doc = fitz.open(str(file_path))
    parts: list[str] = []
    for page in doc:
        text = page.get_text()
        if text.strip():
            parts.append(text)
    doc.close()
    return "\n\n".join(parts)


def _parse_docx(file_path: Path) -> str:
    try:
        from docx import Document
    except ImportError:
        raise ImportError("python-docx not installed")
    doc = Document(str(file_path))
    parts: list[str] = []
    for para in doc.paragraphs:
        if para.text.strip():
            parts.append(para.text)
    return "\n\n".join(parts)


def chunk_text(text: str, max_tokens: int = 500, overlap_tokens: int = 50) -> list[dict[str, Any]]:
    try:
        import tiktoken
        enc = tiktoken.get_encoding("cl100k_base")
        def count(s: str) -> int:
            return len(enc.encode(s))
    except ImportError:
        enc = None
        def count(s: str) -> int:
            return len(s) // 4

    sections: list[tuple[int, str]] = [(0, "")]
    for m in HEADING_RE.finditer(text):
        sections.append((m.start(), m.group()))

    chunks: list[dict[str, Any]] = []
    chunk_index = 0
    start = 0
    text_len = len(text)
    section_idx = 0

    while start < text_len and chunk_index < 1000:
        current_heading = ""
        while section_idx < len(sections) - 1 and sections[section_idx + 1][0] <= start:
            section_idx += 1
            current_heading = sections[section_idx][1]

        remaining = text[start:]
        token_count = count(remaining)
        if token_count <= max_tokens:
            chunk_text_raw = remaining.strip()
            if chunk_text_raw:
                chunks.append({
                    "chunk_index": chunk_index,
                    "content": chunk_text_raw,
                    "metadata": {"heading": current_heading} if current_heading else {},
                })
            break

        end = _find_chunk_end(text, start, max_tokens, count)
        chunk_text_raw = text[start:end].strip()
        if chunk_text_raw:
            chunks.append({
                "chunk_index": chunk_index,
                "content": chunk_text_raw,
                "metadata": {"heading": current_heading} if current_heading else {},
            })
            chunk_index += 1

        overlap_chars = overlap_tokens * 4 if enc is None else _find_char_offset(text, end, -overlap_tokens, count)
        start = max(start + 1, end - overlap_chars)

    return chunks


def _find_chunk_end(text: str, start: int, max_tokens: int, count_fn) -> int:
    low, high = start + 1, len(text)
    while low < high:
        mid = (low + high + 1) // 2
        if count_fn(text[start:mid]) <= max_tokens:
            low = mid
        else:
            high = mid - 1
    return low


def _find_char_offset(text: str, pos: int, target_tokens: int, count_fn) -> int:
    if pos <= 0:
        return 0
    start = max(0, pos - target_tokens * 20)
    low, high = start, pos
    while low < high:
        mid = (low + high) // 2
        if count_fn(text[mid:pos]) <= target_tokens:
            high = mid
        else:
            low = mid + 1
    return pos - low


async def embed_batch(chunks: list[str]) -> list[list[float]]:
    from openai import AsyncOpenAI
    from app.core.config import settings

    client = AsyncOpenAI(
        api_key=settings.FLAZ_API_KEY,
        base_url=settings.FLAZ_BASE_URL,
    )
    embeddings: list[list[float]] = []
    for i in range(0, len(chunks), 20):
        batch = chunks[i : i + 20]
        response = await client.embeddings.create(
            model=settings.EMBEDDING_MODEL,
            input=batch,
        )
        embeddings.extend([item.embedding for item in response.data])
    return embeddings


async def insert_chunks(
    document_id: str,
    chunks: list[dict[str, Any]],
    embeddings: list[list[float]],
) -> None:
    import asyncpg
    from app.core.config import settings

    dsn = settings.DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")
    conn = await asyncpg.connect(dsn=dsn, timeout=5)
    try:
        for chunk, embedding in zip(chunks, embeddings):
            chunk_id = uuid.uuid4()
            await conn.execute(
                """
                INSERT INTO knowledge_chunks (id, document_id, chunk_index, content, embedding, metadata)
                VALUES ($1, $2, $3, $4, $5::vector, $6::jsonb)
                """,
                chunk_id,
                uuid.UUID(document_id),
                chunk["chunk_index"],
                chunk["content"],
                embedding,
                chunk.get("metadata", {}),
            )
    finally:
        await conn.close()


async def update_document_status(
    document_id: str,
    status: str,
    total_chunks: int | None = None,
    error_message: str | None = None,
) -> None:
    import asyncpg
    from app.core.config import settings

    dsn = settings.DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")
    conn = await asyncpg.connect(dsn=dsn, timeout=5)
    try:
        if status == "ready" and total_chunks is not None:
            await conn.execute(
                """
                UPDATE knowledge_documents
                SET status = $1, total_chunks = $2, processed_at = NOW()
                WHERE id = $3
                """,
                status, total_chunks, uuid.UUID(document_id),
            )
        elif status == "failed":
            await conn.execute(
                """
                UPDATE knowledge_documents
                SET status = $1, error_message = $2
                WHERE id = $3
                """,
                status, error_message, uuid.UUID(document_id),
            )
        else:
            await conn.execute(
                "UPDATE knowledge_documents SET status = $1 WHERE id = $2",
                status, uuid.UUID(document_id),
            )
    finally:
        await conn.close()
