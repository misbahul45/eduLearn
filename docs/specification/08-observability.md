# 08 — Logging & Observability

## Tujuan

Mendefinisikan dua lapis logging yang berbeda secara eksplisit: (a) server-side structured log untuk debugging/audit internal, (b) client-facing event stream yang sudah disaring agar aman ditampilkan ke siswa. Halaman ini mencegah kebocoran informasi sensitif ke client dan memastikan trace agent bisa diaudit pasca-insiden.

## Server-side Structured Log

Lokasi: `server/app/core/logging.py`. Logger yang sudah ada dipertahankan, ditambah logger khusus `"agent.trace"` dengan JSON formatter ke stdout.

Setiap event yang dikirim ke client **juga** dicatat di `agent.trace` dengan field tambahan yang TIDAK dikirim ke client:

| Field | Dikirim ke client? | Ke server log? |
|---|---|---|
| `event_type` | ✅ | ✅ |
| `timestamp` | ✅ | ✅ |
| `node` / `tool_name` | ✅ | ✅ |
| `call_id` | ✅ | ✅ |
| `conversation_id` | ❌ (di `final` saja) | ✅ |
| `user_id` | ❌ | ✅ |
| `internal_input_raw` | ❌ | ✅ (full input sebelum sanitasi) |
| `internal_output_raw` | ❌ | ✅ (full output tool) |
| `duration_ms` | ✅ (di `tool_result`) | ✅ |
| `stack_trace` | ❌ | ✅ (saat error) |
| `llm_prompt_template` | ❌ | ✅ (versi rendered, untuk audit prompt injection) |
| `llm_response_tokens` | ❌ | ✅ (token count untuk cost tracking) |
| `firecrawl_api_cost` | ❌ | ✅ (estimasi biaya per call) |

Format log: JSON lines ke stdout (untuk Docker), dikapitalisasi level (`INFO`, `WARN`, `ERROR`). Rotation via Docker `json-file` driver dengan `max-size: 50m`, `max-file: 5`.

## Client-facing Event Stream (Subset Aman)

Aturan sanitasi sebelum event dikirim via WebSocket (`EventSanitizer.sanitize(event)` di `server/app/schemas/events.py`):

1. **Strip `internal_*` fields** — semua field dengan prefix `internal_` tidak boleh dikirim ke client.
2. **Mask API key / token** — bila ada di field `input` tool, ganti dengan `"***"`. Pattern: `sk-*`, `Bearer *`, `password=*`.
3. **Truncate snippet** — `citation.snippet` & `web_search_result.snippet` maksimum 300 karakter.
4. **Truncate markdown_excerpt** — `web_search_result.markdown_excerpt` maksimum 800 karakter.
5. **No stack trace** — field `error.message` wajib human-readable Indonesia, bukan exception class.
6. **No file path** — bila tool error mengandung path `/app/...`, `/usr/...`, `/home/...`, ganti dengan `"[server path]"`.
7. **No LLM raw prompt** — system prompt & few-shot examples tidak boleh muncul di event manapun.
8. **`tool_result.output_summary`** — wajib diringkas menjadi 1 kalimat, bukan dump JSON mentah.
9. **Strip HTML** — semua snippet & excerpt di-escape HTML (`<` → `&lt;`), kecuali markdown dasar diizinkan di `markdown_excerpt` (header `#`, list `-`, bold `**`).

Validator: sebelum `websocket.send_json(event)`, lewatkan ke `EventSanitizer.sanitize(event)` yang mengembalikan dict bersih. Sanitizer di-test dengan unit test yang assert tidak ada substring:
- `"sk-"` (OpenAI-style key)
- `"Bearer "` (auth header)
- `"/app/"`, `"/usr/"`, `"/home/"` (server paths)
- `"Traceback"` (Python stack trace)
- `"system_prompt"` (LLM system prompt key)
- `"api_key"`, `"apiKey"` (key field names)

## EventSanitizer

Implementasi di `server/app/schemas/events.py` — lihat file tersebut.

## Observability Metrik (Opsional)

Metrik Prometheus yang direkomendasi (ekspor via `/metrics` jika `METRICS_ENABLED=true`):

| Metrik | Tipe | Label |
|---|---|---|
| `edulearn_ws_connections_active` | Gauge | — |
| `edulearn_ws_messages_total` | Counter | `direction` (in/out) |
| `edulearn_agent_iterations` | Histogram | — |
| `edulearn_tool_duration_seconds` | Histogram | `tool_name` |
| `edulearn_tool_errors_total` | Counter | `tool_name`, `error_type` |
| `edulearn_llm_tokens_total` | Counter | `direction` (prompt/completion) |
| `edulearn_prediction_label_distribution` | Counter | `predicted_label` (Lulus/Tidak Lulus) |
| `edulearn_firecrawl_calls_total` | Counter | `status` (success/error/timeout) |
| `edulearn_knowledge_uploads_total` | Counter | `file_type`, `status` |

## Wireframe Alur Logging

```
┌──────────────┐  event (raw, with internal_*)   ┌────────────────┐
│  LangGraph   │ ─────────────────────────────►  │  agent.trace   │ ──► stdout JSON
│  node/tool   │                                 │  logger        │     (Docker log)
└──────┬───────┘                                 └────────────────┘
       │
       │ event (raw)
       ▼
┌──────────────────┐  event (sanitized)  ┌──────────────┐
│ EventSanitizer   │ ──────────────────► │  WebSocket   │ ──► Flutter
│  - strip internal │                     │  send_json   │
│  - mask api_key   │                     └──────────────┘
│  - truncate snip  │
│  - no stack trace │
└──────────────────┘
```

## Catatan

- Log server TIDAK menggantikan event client — keduanya wajib. Bila hanya log server, audit pasca-insiden tetap bisa, tapi siswa kehilangan trace live.
- Sanitizer wajib fail-closed: bila ada field tidak dikenal, strip (jangan pass-through).
- Untuk debugging lokal (env `ENVIRONMENT=development` & `WS_DEBUG_RAW_EVENTS=true`), sanitizer bisa di-bypass — **hanya** untuk dev, tidak pernah di production.
- Retensi log server: 30 hari (default Docker json-file rotation), metrik 15 hari di Prometheus.
- `agent.trace` logger wajib include `conversation_id` & `user_id` di setiap log entry untuk korelasi pasca-insiden.
- Audit log (PostgreSQL `audit_conversations` table) menampung ringkasan per conversation selesai — lihat `10-security.md` jika tersedia.
