# 04 — Kontrak Realtime (WebSocket Event Schema)

## Tujuan

Mendefinisikan semua tipe event WebSocket beserta payload JSON lengkap. Halaman ini adalah kontrak binding antara backend & Flutter.

## Endpoint & Auth

- **Endpoint**: `WEBSOCKET /ws/v1/chat`
- **Auth**: JWT via query `token=<jwt>`.
- **Heartbeat**: server ping tiap `WS_HEARTBEAT_INTERVAL` (20s); client bales pong dalam `WS_HEARTBEAT_TIMEOUT` (30s).

## Daftar Event (9 type)

### 4.1 `state_update`

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

### 4.2 `tool_call`

```json
{
  "type": "tool_call",
  "tool_name": "rag_tool",
  "input": { "query": "apa itu neural network" },
  "call_id": "call_abc123",
  "timestamp": "2026-07-04T10:00:00.456Z"
}
```

### 4.3 `tool_result`

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

### 4.4 `token`

```json
{
  "type": "token",
  "content": "Neural",
  "index": 0
}
```

### 4.5 `prediction_result`

```json
{
  "type": "prediction_result",
  "data": {
    "predicted_label": "Lulus",
    "confidence": 0.87,
    "class_scores": [
      {"label": "Tidak Lulus", "score": 0.13},
      {"label": "Lulus", "score": 0.87}
    ],
    "model_name": "Deep MLP",
    "model_version": "1.0.0",
    "input_features_used": [
      "time_spent_minutes",
      "video_completion_rate",
      "quiz_attempts",
      "quiz_score_avg"
    ],
    "generated_at": "2026-07-04T10:00:03.000Z"
  }
}
```

### 4.6 `citation`

```json
{
  "type": "citation",
  "source_id": "doc_42",
  "snippet": "Neural network adalah model komputasi...",
  "score": 0.91,
  "metadata": {
    "title": "Pengantar Deep Learning",
    "author": "Dr. X",
    "page": 12
  }
}
```

### 4.7 `web_search_result`

```json
{
  "type": "web_search_result",
  "result_id": "ws_001",
  "url": "https://example.com/article",
  "title": "Neural Networks in 2026",
  "snippet": "Recent advances...",
  "source": "firecrawl",
  "relevance_score": 0.85,
  "timestamp": "2026-07-04T10:00:02.000Z"
}
```

### 4.8 `final`

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

### 4.9 `error`

```json
{
  "type": "error",
  "node": "rag_tool",
  "message": "Gagal mengambil referensi",
  "fatal": false,
  "timestamp": "2026-07-04T10:00:01.000Z"
}
```

## Aturan

- Semua event punya `type` dan `timestamp` ISO 8601 UTC.
- `call_id` korelasi `tool_call` <-> `tool_result`.
- Tidak ada `stack_trace`, `internal_prompt`, `api_key` di event.
- Schema Pydantic v2 di `app/schemas/events.py`.

## Alur Event

```
Client                          Server
  │ -- connect (JWT) ------------>│
  │ -- send message ------------->│
  │ <-- state_update supervisor  │
  │ <-- tool_call rag_tool       │
  │ <-- citation x 3             │
  │ <-- tool_result rag_tool     │
  │ <-- tool_call predictive     │
  │ <-- prediction_result        │
  │ <-- tool_result predictive   │
  │ <-- tool_call firecrawl      │
  │ <-- web_search x 1           │
  │ <-- tool_result firecrawl    │
  │ <-- state_update response    │
  │ <-- token x N                │
  │ <-- final                    │
  │ <-- ping (heartbeat) -------│
  │ -- pong --------------------->│
```
