# Contract: Chat

## REST Fallback: `POST /api/v1/chat`

Endpoint untuk chat non-streaming, dipakai saat WebSocket gagal connect.

### Request

Header: `Authorization: Bearer <access_token>`

```json
{
  "message": "Apa itu neural network?",
  "conversation_id": null
}
```

`conversation_id` opsional. Jika null, server buat UUID baru.

### Response 200

```json
{
  "message": "Neural network adalah...",
  "conversation_id": "uuid-conv-789"
}
```

### Response 400

```json
{
  "detail": "Message must not be empty"
}
```

---

## WebSocket: `WEBSOCKET /ws/v1/chat`

### Connection

```
ws://localhost:8000/ws/v1/chat?token=<JWT_ACCESS_TOKEN>
```

### Authentication

JWT via subprotocol `Sec-WebSocket-Protocol: bearer.<token>` (preferred) atau query parameter `token` (fallback). Koneksi ditolak dengan 4001 jika token invalid/expired.

### Client → Server Events

#### `user_message`

```json
{
  "type": "user_message",
  "message": "Apa itu neural network?",
  "conversation_id": null
}
```

#### `ping`

```json
{
  "type": "ping"
}
```

### Server → Client Events

Daftar lengkap server events (9 type) ada di `07-events.md`:
- `state_update` — node LangGraph berganti
- `tool_call` / `tool_result` — tool invocation lifecycle
- `token` — streaming jawaban LLM
- `prediction_result` — output ML binary classification
- `citation` — referensi RAG lokal
- `web_search_result` — hasil Firecrawl
- `final` — jawaban selesai
- `error` — error non-fatal / fatal

### Pong

```json
{
  "type": "pong"
}
```

---

## `WEBSOCKET /ws/v1/health`

Ping-only endpoint untuk Docker HEALTHCHECK. Tidak perlu auth.

### Flow

```
Client → {"type": "ping"}
Server → {"type": "pong"}
```
