# API Contracts — Index

Dokumen ini berisi kontrak API **binding** antara backend (FastAPI) dan client (Flutter). Perubahan field wajib update di kedua sisi secara sinkron.

## Base URLs

| Mode | URL |
|---|---|
| Local development | `http://localhost:8000` |
| Via Nginx (Docker) | `http://localhost:80` |
| WebSocket (local) | `ws://localhost:8000/ws/v1/...` |
| WebSocket (via Nginx) | `ws://localhost/ws/v1/...` |

## Daftar Kontrak

| # | File | Isi |
|---|------|-----|
| 01 | `01-health.md` | `GET /health` — health check, model status, uptime |
| 02 | `02-auth.md` | `POST /auth/login|register|logout|refresh`, `GET /auth/me` — JWT auth |
| 03 | `03-users.md` | `GET /users/me`, `GET /users/stats` — profil & statistik user |
| 04 | `04-predictions.md` | `GET /predictions/latest|history|analysis` — prediksi ML |
| 05 | `05-knowledge.md` | `POST /knowledge/upload` — upload file ke knowledge base |
| 06 | `06-chat.md` | REST `POST /api/v1/chat` + WS `/ws/v1/chat` — chat endpoint |
| 07 | `07-events.md` | WebSocket event schema (9 event types) — kontrak realtime |

## Status Codes

| Code | Deskripsi |
|---|---|
| 200 | Success |
| 201 | Created (upload) |
| 400 | Bad request (validasi) |
| 401 | Unauthorized (token invalid/expired) |
| 403 | Forbidden |
| 404 | Not found |
| 413 | File too large (upload) |
| 415 | Unsupported file type (upload) |
| 422 | Validation error |
| 429 | Rate limited |
| 500 | Internal server error |
| 503 | Service unavailable (model not loaded) |
