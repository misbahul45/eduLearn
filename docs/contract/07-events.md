# Contract: WebSocket Events

## Tujuan

Mendefinisikan semua tipe event WebSocket beserta payload JSON lengkap. Halaman ini adalah kontrak **binding** antara backend & Flutter — perubahan field wajib update di kedua sisi secara sinkron.

## Endpoint & Auth

- **Endpoint**: `WEBSOCKET /ws/v1/chat`
- **Auth**: JWT via subprotocol `Sec-WebSocket-Protocol: bearer.<token>` (preferred) atau query `?token=<jwt>` (fallback). Detail di `../specification/10-security.md`.
- **Heartbeat**: server kirim `{"type":"ping"}` tiap `WS_HEARTBEAT_INTERVAL` (default 20s); client wajib balas `{"type":"pong"}` dalam `WS_HEARTBEAT_TIMEOUT` (default 30s), jika tidak dianggap mati & disconnect.

## Daftar Event (9 type)

### 7.1 `state_update`

Dikirim setiap kali node LangGraph aktif berganti (start atau end).

```json
{
  "type": "state_update",
  "node": "supervisor",
  "status": "started",
  "iteration": 1,
  "timestamp": "2026-07-04T10:00:00.123Z"
}
```

- `status`: `"started"` | `"completed"`
- `node`: `"supervisor"` | `"rag_tool"` | `"predictive_tool"` | `"firecrawl_tool"` | `"response_node"`

### 7.2 `tool_call`

Dikirim saat supervisor memanggil tool (sebelum eksekusi).

```json
{
  "type": "tool_call",
  "tool_name": "rag_tool",
  "input": { "query": "apa itu neural network" },
  "call_id": "call_abc123",
  "timestamp": "2026-07-04T10:00:00.456Z"
}
```

`input` boleh di-mask sebagian bila mengandung data sensitif (lihat `../specification/10-security.md`).

### 7.3 `tool_result`

Dikirim saat tool selesai.

```json
{
  "type": "tool_result",
  "tool_name": "rag_tool",
  "call_id": "call_abc123",
  "output_summary": "3 dokumen relevan ditemukan",
  "duration_ms": 142,
  "timestamp": "2026-07-04T10:00:00.598Z"
}
```

`output_summary` ringkas — payload detail dikirim via event khusus (`citation` / `prediction_result` / `web_search_result`).

### 7.4 `token`

Streaming token jawaban dari LLM.

```json
{
  "type": "token",
  "content": "Neural",
  "index": 0
}
```

`index` increment per token, supaya client bisa deteksi gap/reorder.

### 7.5 `prediction_result`

Dikirim saat predictive tool menghasilkan output. **Sesuai ML asli (binary classification)**.

```json
{
  "type": "prediction_result",
  "node": "predictive_node",
  "data": {
    "predicted_label": "Lulus",
    "confidence": 0.87,
    "class_scores": [
      {"label": "Tidak Lulus", "score": 0.13},
      {"label": "Lulus", "score": 0.87}
    ],
    "model_name": "Deep MLP (TensorFlow)",
    "model_version": "1.0.0",
    "input_features_used": [
      "time_spent_minutes",
      "video_completion_rate",
      "quiz_attempts",
      "quiz_score_avg",
      "education_level",
      "learning_path_type"
    ],
    "generated_at": "2026-07-04T10:00:03.000Z"
  }
}
```

Detail skema & arti field di `../specification/06-ml-prediction.md`.

### 7.6 `citation`

Dikirim saat rag tool menemukan sumber lokal (dari pgvector). Satu event per citation.

```json
{
  "type": "citation",
  "source_id": "doc_42",
  "snippet": "Neural network adalah model komputasi yang terinspirasi dari...",
  "score": 0.91,
  "metadata": {
    "title": "Pengantar Deep Learning",
    "author": "Dr. X",
    "page": 12,
    "document_id": "kd_001",
    "file_name": "deep_learning.pdf"
  }
}
```

### 7.7 `web_search_result`

Dikirim saat firecrawl tool menemukan hasil web. Satu event per result.

```json
{
  "type": "web_search_result",
  "result_id": "ws_001",
  "url": "https://example.com/article",
  "title": "Neural Networks in 2026: A Comprehensive Guide",
  "snippet": "Recent advances in neural network architectures have...",
  "markdown_excerpt": "## Introduction\nNeural networks are computational models...",
  "source": "firecrawl",
  "relevance_score": 0.85,
  "timestamp": "2026-07-04T10:00:02.000Z"
}
```

Detail di `../specification/07-firecrawl-tool.md`.

### 7.8 `final`

Dikirim saat jawaban selesai disusun.

```json
{
  "type": "final",
  "message": "Neural network adalah...",
  "conversation_id": "uuid-1234",
  "citations": ["doc_42", "doc_88"],
  "web_results": ["ws_001"],
  "prediction_present": true,
  "prediction_label": "Lulus",
  "timestamp": "2026-07-04T10:00:03.789Z"
}
```

### 7.9 `error`

Dikirim bila satu langkah gagal tapi sesi tetap jalan (tidak fatal).

```json
{
  "type": "error",
  "node": "rag_tool",
  "message": "Gagal mengambil referensi, melanjutkan tanpa sitasi",
  "fatal": false,
  "timestamp": "2026-07-04T10:00:01.000Z"
}
```

`fatal: true` ⇒ server akan menutup koneksi setelah event ini dikirim.

## Aturan Umum

- Semua event wajib punya `type` dan `timestamp` (ISO 8601 UTC, format `2026-07-04T10:00:00.123Z`).
- `call_id` digunakan untuk korelasi `tool_call` ↔ `tool_result`.
- Schema Pydantic v2 wajib dibuat di `app/schemas/events.py`.
- **Tidak boleh ada field** `stack_trace`, `internal_prompt`, `api_key`, atau path file server di event manapun. Sanitasi detail di `../specification/08-observability.md`.

## Wireframe Alur Event

```
Client                          Server
  │ ── connect (JWT) ────────────►│
  │ ◄── ack (connected) ─────────│
  │ ── send message ─────────────►│
  │ ◄── state_update supervisor  │
  │ ◄── state_update supervisor  │ (completed)
  │ ◄── tool_call rag_tool       │
  │ ◄── citation × 3             │
  │ ◄── tool_result rag_tool     │
  │ ◄── tool_call firecrawl_tool │
  │ ◄── web_search_result × 1    │
  │ ◄── tool_result firecrawl    │
  │ ◄── tool_call predictive_tool│
  │ ◄── prediction_result        │
  │ ◄── tool_result predictive   │
  │ ◄── state_update response    │
  │ ◄── token × N (streaming)    │
  │ ◄── final                    │
  │ ◄── ping (heartbeat) ────────│
  │ ── pong ─────────────────────►│
```

## Catatan

- Client tidak wajib mengirim event selain `pong` dan pesan baru — server yang mendrive seluruh flow.
- Urutan event TIDAK dijamin strict (token bisa datang sebelum `prediction_result` selesai). Client wajib handle out-of-order via `call_id` & `index`.
- Bila koneksi putus di tengah stream, reconnect dengan `conversation_id` sama akan melanjutkan state dari Redis (bukan replay event yang hilang).
- WebSocket juga punya endpoint terpisah `/ws/v1/health` (ping-only, tanpa auth) untuk Docker healthcheck. Lihat `../specification/09-deployment.md`.
