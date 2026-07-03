# 09 — Deployment & Kompatibilitas

## Tujuan

Menjelaskan bagaimana WebSocket di-proxy lewat Nginx, perubahan pada `docker-compose`, health check tambahan untuk WS, dan deployment notes Flutter. Halaman ini wajib dibaca DevOps sebelum deploy perubahan realtime.

## Nginx Config (WebSocket Upgrade)

Blok `location /ws/` diekstrak ke file terpisah `infra/nginx/ws.conf` dan di-include dari `default.conf`:

```nginx
# infra/nginx/ws.conf
location /ws/ {
    proxy_pass http://server:8000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    # Timeout panjang untuk long-lived WS
    proxy_read_timeout 3600s;
    proxy_send_timeout 3600s;

    # Buffering off untuk streaming token
    proxy_buffering off;
}
```

Blok `location /` (REST) tetap di `default.conf`.

## docker-compose Perubahan

### Service `server` — env baru + healthcheck

```yaml
server:
  build: ../server
  environment:
    # ... env lama ...
    WS_MAX_ITERATIONS: 5
    WS_AUTH_REQUIRED: "true"
    WS_DEBUG_RAW_EVENTS: "false"
    WS_CONNECTION_LIMIT_PER_USER: 3
    WS_RATE_MSG_PER_MIN: 30
    WS_RATE_TOOL_PER_CONV: 20
    WS_RATE_TOKENS_PER_CONV: 8000
    REDIS_CONVERSATION_TTL: 86400
    PREDICTION_THRESHOLD: 0.5
    FIRECRAWL_CACHE_TTL: 3600
    UPLOAD_MAX_FILE_SIZE_MB: 20
    UPLOAD_DIR: /app/uploads
    EMBEDDING_MODEL: text-embedding-3-small
    EMBEDDING_DIM: 1536
    METRICS_ENABLED: "false"
    JWT_ACCESS_EXPIRE_MIN: 60
    JWT_REFRESH_EXPIRE_DAYS: 30
  volumes:
    - ../models:/app/models:ro
    - uploads_data:/app/uploads
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
    interval: 30s
    timeout: 5s
    retries: 3
```

### Service `nginx` — tambah volume ws.conf

```yaml
nginx:
  volumes:
    - ./nginx/ws.conf:/etc/nginx/conf.d/ws.conf:ro
```

### Service `postgres` — init pgvector

Sudah ada: `infra/postgres/init.sql` di-mount ke `/docker-entrypoint-initdb.d/init.sql:ro`.

### Volume

```yaml
volumes:
  uploads_data:
```

## Endpoint WS Health-only

`WEBSOCKET /ws/v1/health` — endpoint tanpa auth, hanya respond `{"type":"pong"}` ke `{"type":"ping"}`.

Implementasi sudah ada di `server/app/api/chat_ws.py`.

## Konfigurasi via `infra/.env`

Lihat `server/app/core/config.py` — semua via `pydantic-settings`. Variabel yang ditambahkan/diubah:

| Variable | Default | Description |
|---|---|---|
| `WS_MAX_ITERATIONS` | `5` | Maksimum iterasi supervisor sebelum paksa respond |
| `WS_AUTH_REQUIRED` | `true` | Wajib JWT untuk connect WS |
| `WS_DEBUG_RAW_EVENTS` | `false` | Bypass sanitizer (dev only) |
| `WS_CONNECTION_LIMIT_PER_USER` | `3` | Maksimum WS aktif per user |
| `WS_RATE_MSG_PER_MIN` | `30` | Rate limit pesan masuk |
| `WS_RATE_TOOL_PER_CONV` | `20` | Rate limit tool call per conversation |
| `WS_RATE_TOKENS_PER_CONV` | `8000` | Rate limit token LLM per conversation |
| `REDIS_CONVERSATION_TTL` | `86400` | TTL state percakapan di Redis (detik) |
| `PREDICTION_THRESHOLD` | `0.5` | Threshold binary classifier |
| `FIRECRAWL_CACHE_TTL` | `3600` | TTL cache Firecrawl di Redis (detik) |
| `UPLOAD_MAX_FILE_SIZE_MB` | `20` | Maksimum ukuran file upload (MB) |
| `UPLOAD_ALLOWED_TYPES` | `pdf,docx,txt,md` | Ekstensi file yang diizinkan |
| `UPLOAD_DIR` | `/app/uploads` | Direktori penyimpanan file upload |
| `EMBEDDING_MODEL` | `text-embedding-3-small` | Model embedding untuk RAG |
| `EMBEDDING_DIM` | `1536` | Dimensi embedding |
| `METRICS_ENABLED` | `false` | Enable Prometheus `/metrics` endpoint |
| `JWT_ACCESS_EXPIRE_MIN` | `60` | Access token expiry (menit) |
| `JWT_REFRESH_EXPIRE_DAYS` | `30` | Refresh token expiry (hari) |

## Wireframe Arsitektur Deployment

```
┌─────────┐    WSS     ┌────────┐   HTTP    ┌─────────┐
│ Flutter │ ─────────► │ Nginx  │ ────────► │ FastAPI │
│  app    │            │ (WS    │  upgrade  │ (WS +   │
│         │            │  proxy)│           │  REST)  │
└─────────┘            └────────┘           └────┬────┘
                                                 │
                              ┌──────────────────┼─────────────┐
                              ▼                  ▼             ▼
                         PostgreSQL          Redis 7      ML models
                         17 + pgvector     (state +       (read-only
                         (knowledge +      cache +         mount)
                         audit)            rate limit)
                                                 │
                                                 ▼
                                          Firecrawl API
                                          (external)
```
