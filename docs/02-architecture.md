# 02 — Arsitektur Sistem (High-Level)

## Tujuan

Menjelaskan alur end-to-end dari client (Flutter) sampai tool (RAG/ML/Firecrawl) dan kembali, dengan penjelasan eksplisit bedanya dengan arsitektur lama (fan-out tetap) vs baru (reasoning loop). Halaman ini adalah rujukan visual untuk semua perubahan kode backend & infra.

## Arsitektur Target

```
┌────────────┐      WSS /ws/v1/chat        ┌────────────┐
│  Flutter   │ ◄──────────────────────────► │   Nginx    │
│  (Riverpod │   (event stream bidirectional)│ (WS proxy) │
│  + WS svc) │                              └─────┬──────┘
└────────────┘                                    │
       ▲                                          ▼
       │ REST POST /api/v1/chat            ┌────────────┐
       │ REST POST /api/v1/knowledge/      │  FastAPI   │
       │       upload (file)               │  (async)   │
       └──────────────────────────────────►└─────┬──────┘
                                                 │
                                                 ▼
                                  ┌──────────────────────────────┐
                                  │  LangGraph Supervisor        │
                                  │  (ReAct reasoning loop)      │
                                  │  ┌────────────────────────┐  │
                                  │  │  scratchpad state      │  │
                                  │  │  iteration counter     │  │
                                  │  │  tool call history     │  │
                                  │  └────────────────────────┘  │
                                  └─┬──────────┬──────────┬──────┘
                                    │          │          │
                       (dynamic)    │          │          │ (dynamic)
                                    ▼          ▼          ▼
                              ┌─────────┐ ┌──────────┐ ┌────────────┐
                              │rag_tool │ │predictive│ │firecrawl_  │
                              │(pgvec)  │ │_tool     │ │tool (web)  │
                              └────┬────┘ └────┬─────┘ └─────┬──────┘
                                   │           │             │
                                   └─────┬─────┴─────────────┘
                                         │
                                         ▼
                              ┌────────────────────┐
                              │  response_node     │
                              │  (LLM streaming)   │
                              └─────────┬──────────┘
                                        │
                                        ▼
                                token → client
```

## Komponen Infrastruktur

- **Nginx** — reverse proxy, wajib handle WebSocket upgrade (`Upgrade`, `Connection` header). Detail di `09-deployment.md`.
- **FastAPI** — async, expose WS + REST. Lifespan loader singleton Predictor (fail-fast).
- **LangGraph** — `StateGraph` dengan `supervisor ⇄ tools ⇄ response_node`. Detail di `03-agent-orchestration.md`.
- **PostgreSQL 17 + pgvector** — basis pengetahuan RAG (dokumen yang diupload di-embed & disimpan di sini). Juga menyimpan `audit_conversations` & `users` table.
- **Redis 7** — state percakapan per `conversation_id` + cache embedding + rate limit token bucket.
- **ML models** — read-only mount `/app/models` (`model.weights.h5`, `pipeline.joblib`, `metadata.json`, `config.json`).
- **Firecrawl API** — external service untuk web search. API key di `infra/.env` (`FIRECRAWL_API_KEY`).

## Perbedaan Arsitektur Lama vs Baru

| Aspek | Lama | Baru |
|---|---|---|
| Pola supervisor | Fan-out paralel tetap (`Send` ke `predictive_node` + `rag_node` selalu) | Reasoning loop — supervisor memilih 0..N tool per iterasi |
| Jumlah tool | 2 (rag, predictive) | **3** (rag, predictive, **firecrawl**) |
| Transport | REST `POST /api/v1/chat` saja | WebSocket `/ws/v1/chat` (utama) + REST (fallback) |
| Visibilitas proses | Client hanya melihat hasil final | Client melihat `state_update`, `tool_call`, `tool_result`, `token`, `prediction_result`, `citation`, `web_search_result`, `final` secara live |
| Output prediksi | Hanya teks dalam jawaban LLM | Payload `prediction_result` terstruktur (binary label + probability + class_scores) |
| Knowledge source | RAG lokal saja | RAG lokal (pgvector) + **Firecrawl web search** + **File upload API** |
| State percakapan | Tidak persisten lintas koneksi | Disimpan di Redis per `conversation_id` |
| Loop guard | Tidak ada (1 putaran tetap) | `max_iterations` (default 5, via `WS_MAX_ITERATIONS`) |

## Transport Layer

### WebSocket (utama)

- Endpoint: `WEBSOCKET /ws/v1/chat`
- Auth: JWT (lihat `10-security.md`)
- Bidirectional: client kirim message, server stream events
- Heartbeat: server ping setiap 20s, client wajib pong dalam 30s

### REST (fallback + endpoints lain)

| Endpoint | Method | Tujuan |
|---|---|---|
| `/api/v1/chat` | POST | Chat non-streaming (fallback bila WS gagal) |
| `/api/v1/auth/login` | POST | Login |
| `/api/v1/auth/register` | POST | Register |
| `/api/v1/auth/logout` | POST | Logout (invalidate refresh token) |
| `/api/v1/auth/refresh` | POST | Refresh access token |
| `/api/v1/auth/me` | GET | Validate token & get current user |
| `/api/v1/users/me` | GET | User profile |
| `/api/v1/users/stats` | GET | User statistics (total conversations, predictions, avg score) |
| `/api/v1/predictions/latest` | GET | Latest prediction for current user |
| `/api/v1/predictions/history?days=N` | GET | N-day prediction history |
| `/api/v1/predictions/analysis` | GET | Aggregated analysis (distribution, strengths, recommendations) |
| `/api/v1/knowledge/upload` | POST (multipart) | Upload file ke knowledge base (lihat `11-file-upload-api.md`) |
| `/health` | GET | Health check (kontrak tidak berubah) |
| `/ws/v1/health` | WEBSOCKET | WS ping-only untuk Docker healthcheck |

## Data Flow: Chat Realtime

```
1. Siswa buka app → Flutter connect WS /ws/v1/chat (JWT)
2. Siswa kirim message text via WS
3. Server: supervisor reasoning
   ├── state_update: supervisor started
   ├── (opsional) tool_call rag_tool
   │   ├── citation × N (jika ada)
   │   └── tool_result rag_tool
   ├── (opsional) tool_call firecrawl_tool
   │   ├── web_search_result × N
   │   └── tool_result firecrawl_tool
   ├── (opsional) tool_call predictive_tool
   │   ├── prediction_result (binary: Lulus/Tidak Lulus + prob)
   │   └── tool_result predictive_tool
   └── state_update: response_node started
4. Server: LLM stream jawaban
   └── token × N (append ke bubble)
5. Server: final event
   { message, conversation_id, citations, web_results, prediction_present }
6. State conversation disimpan di Redis (TTL 24 jam)
```

## Catatan

- Flutter memilih WS sebagai default. REST fallback otomatis aktif bila WS gagal connect 3x atau disconnect di tengah sesi dan reconnect gagal. Detail strategi reconnect di `16-flutter-chat.md`.
- Server tetap menyajikan `/health` tanpa perubahan kontrak (lihat `09-deployment.md`).
- Singleton Predictor & fail-fast startup tetap dipertahankan — bila model gagal load, seluruh server tidak start.
- ML layer, RAG layer, & Firecrawl client **tetap tidak tahu** soal LangGraph; mereka hanya expose fungsi `predict()` / `search()` / `web_search()` / `ingest()`. Tool wrapper di `app/agent/tools/` yang memanggil mereka.
