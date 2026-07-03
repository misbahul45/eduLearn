# 11 — File Upload API (Knowledge Ingestion)

## Tujuan

Endpoint REST untuk upload file ke knowledge base RAG. File di-parse, di-chunk, di-embed, lalu disimpan di pgvector.

## Endpoints

### `POST /api/v1/knowledge/upload`

Upload file. Auth: Bearer JWT (hanya `pengajar`/`admin`). Content-Type: `multipart/form-data`.

**Request fields**: `file` (binary, wajib, max 20MB), `title`, `author`, `description`, `tags` (comma-sep, opsional).

**Response 201**:
```json
{
  "document_id": "kd_...",
  "file_name": "deep_learning.pdf",
  "file_type": "pdf",
  "file_size_bytes": 1048576,
  "title": "Deep Learning Chapter 1",
  "status": "processing",
  "message": "File diterima, sedang diproses (chunking + embedding).",
  "created_at": "2026-07-04T10:00:00.000Z"
}
```

**Response 400**: Ekstensi tidak diizinkan / spoofing magic number.
**Response 413**: File > 20MB.
**Response 429**: Rate limit harian.

### `GET /api/v1/knowledge/{document_id}`

Cek status dokumen. Response includes `total_chunks`, `status` (`processing`|`ready`|`failed`), `error_message`.

### `GET /api/v1/knowledge`

List dokumen dengan pagination. Query params: `page`, `page_size`, `status`, `search`.

### `DELETE /api/v1/knowledge/{document_id}`

Hapus dokumen + chunks + file asli. Hanya pemilik atau admin.

## Pipeline Ingestion

```
1. Save file → /app/uploads/{document_id}/{sanitized_filename}
2. Insert knowledge_documents (status='processing')
3. Background task:
   a. Parse: PDF → PyMuPDF, DOCX → python-docx, TXT/MD → read
   b. Chunk: 500 token, overlap 50, preserve heading
   c. Embed: text-embedding-3-small (1536 dim)
   d. Batch INSERT ke knowledge_chunks
   e. Update status='ready'
4. On failure: status='failed', error_message Indonesia
```

## Schema

Lihat `server/app/schemas/knowledge.py` — `KnowledgeUploadResponse`, `KnowledgeDocument`, `KnowledgeListResponse`.

## Dependencies

`pymupdf`, `python-docx`, `tiktoken`, `python-multipart`, `aiofiles`.

## Flutter

Upload via `dio` + `FormData`. Poll status tiap 3 detik. List dokumen di Profile page.
