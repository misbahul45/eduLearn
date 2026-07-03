# Contract: WebSocket Chat

## `WEBSOCKET /ws/v1/chat`

### Connection

```
ws://localhost:8000/ws/v1/chat?token=<JWT_ACCESS_TOKEN>
```

### Authentication

JWT dikirim sebagai query parameter `token`. Koneksi ditolak dengan 4001 jika token invalid/expired.

### Client → Server Events

#### `user_message`

```json
{
  "type": "user_message",
  "message": "Apa itu neural network?",
  "conversation_id": null
}
```

`conversation_id` opsional. Jika null, server buat UUID baru.

#### `ping`

```json
{
  "type": "ping"
}
```

### Server → Client Events

#### `state_update`

```json
{
  "type": "state_update",
  "state": "supervisor",
  "message": "Menganalisis pertanyaan..."
}
```

State values: `supervisor`, `rag_tool`, `predictive_tool`, `firecrawl_tool`, `response_node`

#### `tool_call`

```json
{
  "type": "tool_call",
  "tool": "rag_tool",
  "input": {
    "query": "neural network definition"
  }
}
```

#### `tool_result`

```json
{
  "type": "tool_result",
  "tool": "rag_tool",
  "output": {
    "results_count": 2
  }
}
```

#### `token`

```json
{
  "type": "token",
  "token": "Neural"
}
```

Streaming token-by-token dari LLM.

#### `citation`

```json
{
  "type": "citation",
  "document": "Bab 1 - Neural Network.pdf",
  "snippet": "Neural network adalah sistem komputasi yang terinspirasi...",
  "relevance": 0.94
}
```

#### `web_search_result`

```json
{
  "type": "web_search_result",
  "url": "https://example.com/neural-network",
  "title": "Pengertian Neural Network",
  "snippet": "Neural network adalah..."
}
```

#### `prediction_result`

```json
{
  "type": "prediction_result",
  "label": "Lulus",
  "probability": 0.8732,
  "class_scores": {
    "Tidak Lulus": 0.1268,
    "Lulus": 0.8732
  }
}
```

#### `final`

```json
{
  "type": "final",
  "message": "Neural network adalah sistem komputasi yang...",
  "conversation_id": "uuid-conv-789",
  "citations": [
    {
      "document": "Bab 1 - Neural Network.pdf",
      "snippet": "Neural network adalah sistem komputasi..."
    }
  ],
  "web_results": [
    {
      "url": "https://example.com/neural-network",
      "title": "Pengertian Neural Network"
    }
  ],
  "prediction_present": true
}
```

#### `error`

```json
{
  "type": "error",
  "code": "rate_limited",
  "message": "Terlalu banyak permintaan. Silakan tunggu beberapa saat."
}
```

Error codes: `rate_limited`, `token_expired`, `internal_error`, `invalid_message`

#### `pong`

```json
{
  "type": "pong"
}
```

## `WEBSOCKET /ws/v1/health`

Ping-only endpoint untuk Docker HEALTHCHECK.

### Flow

```
Client → {"type": "ping"}
Server → {"type": "pong"}
```
