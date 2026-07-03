# Knowledge / RAG System

## Tujuan

Menjelaskan bagaimana hasil retrieval RAG ditampilkan sebagai sitasi/sumber di chat — bukan dibuang menjadi teks mentah di jawaban LLM. Juga menjelaskan arsitektur RAG: pgvector sebagai vector store, embedding, retrieval flow. Proses upload file ke knowledge base ada di `11-file-upload.md`.

## Arsitektur RAG

### Penyimpanan

- **Vector store**: PostgreSQL 17 dengan extension `pgvector`.
- Tabel `knowledge_chunks`:

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | UUID | Primary key |
| `document_id` | UUID | FK ke `knowledge_documents` |
| `chunk_index` | int | Urutan chunk dalam dokumen |
| `content` | text | Teks chunk (300-500 token) |
| `embedding` | vector(1536) | Embedding LLM (OpenAI text-embedding-3-small atau compatible) |
| `metadata` | jsonb | `{page, section, file_name, uploaded_by, ...}` |
| `created_at` | timestamptz | |

- Tabel `knowledge_documents`:

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | UUID | Primary key |
| `file_name` | text | Nama file asli |
| `file_type` | text | `pdf` / `docx` / `txt` / `md` |
| `file_size_bytes` | bigint | |
| `total_chunks` | int | Jumlah chunk yang dihasilkan |
| `uploaded_by` | UUID | FK ke `users` |
| `status` | text | `processing` / `ready` / `failed` |
| `error_message` | text | null bila sukses |
| `created_at` | timestamptz | |
| `processed_at` | timestamptz | null bila masih processing |

### Index

- HNSW index pada kolom `embedding` untuk approximate nearest neighbor search:
  ```sql
  CREATE INDEX ON knowledge_chunks USING hnsw (embedding vector_cosine_ops)
  WITH (m = 16, ef_construction = 64);
  ```
- B-tree index pada `document_id` & `created_at`.

## Alur Retrieval

1. `rag_tool(query: str)` di `app/agent/tools/rag_tool.py` memanggil `Retriever.search(query, k=3)`.
2. `Retriever.search()` (di `app/rag/retriever.py`):
   - Embed `query` via LLM embedding API.
   - Query pgvector: `SELECT id, content, metadata, 1 - (embedding <=> $1) AS score FROM knowledge_chunks ORDER BY embedding <=> $1 LIMIT 3`.
   - Filter hanya `document_id` dengan `status = 'ready'`.
   - Return `list[Citation]` (top-3 + skor cosine similarity).
3. Tool mengembalikan `list[Citation]` ke scratchpad supervisor.
4. Untuk setiap citation, server emit event `citation` (lihat `contract/07-events.md` §7.6) ke client — tidak menunggu jawaban final.
5. `response_node` menerima citation di scratchpad, menyusun jawaban LLM dengan instruction prompt untuk menambah `[1]`, `[2]`, `[3]` inline.
6. Client merender `[1]` sebagai chip yang tappable → expand source.

## Skema Data

```python
# app/schemas/knowledge.py
from pydantic import BaseModel

class CitationMeta(BaseModel):
    title: str | None = None
    author: str | None = None
    page: int | None = None
    url: str | None = None
    document_id: str | None = None
    file_name: str | None = None

class Citation(BaseModel):
    source_id: str          # chunk UUID
    snippet: str            # max 300 char (sudah di-sanitize)
    score: float            # cosine similarity [0, 1]
    metadata: CitationMeta
```

## Tampilan di Flutter

Lihat detail di `16-flutter-chat.md` (sub-widget `CitationExpansionTile`). Ringkasan:

- Bubble chat assistant berisi teks jawaban + nomor sitasi inline.
- Di bawah bubble, `CitationExpansionTile` (collapsible) menampilkan daftar sumber:
  - Nomor `[1]`, `[2]`, `[3]`.
  - Snippet teks (di-truncate ke 200 char + "…").
  - Metadata: judul, penulis, halaman, nama file.
  - Skor relevansi sebagai badge (`91% match`).
- Tap nomor sitasi inline di bubble → scroll ke citation bersangkutan di tile + highlight 2 detik.

## Wireframe Citation di Bubble

```
┌─────────────────────────────────────┐
│ 🤖 Assistant                        │
│ Neural network adalah model         │
│ komputasi yang terinspirasi dari    │
│ neuron biologis [1]. Setiap neuron  │
│ menerima input, memproses, dan      │
│ menghasilkan output [2].            │
│                                     │
│ ▼ Sumber referensi (3)              │
│   ┌─────────────────────────────┐   │
│   │ [1] Pengantar Deep Learning │   │
│   │ Dr. X · hal 12 · 91% match  │   │
│   │ "Neural network adalah..."  │   │
│   └─────────────────────────────┘   │
│   ┌─────────────────────────────┐   │
│   │ [2] ...                     │   │
│   └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

## Catatan

- Bila skor tertinggi < 0.5 (low confidence), supervisor boleh skip RAG dan langsung call `firecrawl_tool` (web search) atau minta LLM menjawab dengan disclaimer. Client tetap render bubble tanpa citation tile.
- Snippet di event `citation` wajib sudah di-sanitize (escape HTML, strip PII, max 300 char).
- Maksimum 5 citation per bubble agar UI tidak overflow; sisanya di-collapse jadi "+N lainnya".
- Penomoran `[1]`, `[2]` urut berdasarkan skor tertinggi → terendah.
- Knowledge ingestion (file upload → chunking → embedding → insert ke pgvector) ada di `11-file-upload.md`.
- Embedding model dapat di-override via env `EMBEDDING_MODEL` (default `text-embedding-3-small`, dimensi 1536). Bila diganti, dimensi kolom `embedding` di pgvector & HNSW index wajib re-create.
- Retriever tidak boleh tahu soal LangGraph — `Retriever.search()` adalah fungsi murni yang return `list[Citation]`. Tool wrapper yang mengubahnya jadi tool call.
