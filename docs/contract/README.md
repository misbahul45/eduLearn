# API Contracts — EduLearn AI

Dokumen ini berisi kontrak API antara backend (FastAPI) dan client (Flutter).

## Base URLs

| Mode | URL |
|---|---|
| Local development | `http://localhost:8000` |
| Via Nginx (Docker) | `http://localhost:80` |
| WebSocket (local) | `ws://localhost:8000/ws/v1/...` |
| WebSocket (via Nginx) | `ws://localhost/ws/v1/...` |

## REST Endpoints

| Method | Path | Auth | Deskripsi |
|--------|------|------|-----------|
| GET | `/health` | No | Health check |
| POST | `/api/v1/chat` | Yes | REST fallback chat (non-streaming) |
| POST | `/api/v1/auth/login` | No | Login |
| POST | `/api/v1/auth/register` | No | Register |
| POST | `/api/v1/auth/logout` | Yes | Logout |
| POST | `/api/v1/auth/refresh` | Yes | Refresh JWT |
| GET | `/api/v1/users/me` | Yes | Profile user |
| GET | `/api/v1/users/stats` | Yes | Statistik user |
| GET | `/api/v1/predictions/latest` | Yes | Prediksi terakhir |
| GET | `/api/v1/predictions/history` | Yes | Riwayat prediksi |
| GET | `/api/v1/predictions/analysis` | Yes | Analisis prediksi |
| POST | `/api/v1/knowledge/upload` | Yes | Upload file ke knowledge base |

## WebSocket Endpoint

| Path | Auth | Deskripsi |
|------|------|-----------|
| `/ws/v1/chat` | Query param `token=JWT` | Realtime chat dengan agent |

## Event Types (WebSocket)

Daftar lengkap event ada di `docs/04-websocket-events.md`.

## Status Codes

| Code | Deskripsi |
|------|-----------|
| 200 | Success |
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
