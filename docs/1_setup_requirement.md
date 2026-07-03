# ML Prak — Infra & Setup Requirements

## Table of Contents

- [1. Project Overview](#1-project-overview)
- [2. Prerequisites](#2-prerequisites)
- [3. Project Structure](#3-project-structure)
- [4. Service Descriptions](#4-service-descriptions)
  - [4.1 Nginx (Reverse Proxy)](#41-nginx-reverse-proxy)
  - [4.2 PostgreSQL + pgvector](#42-postgresql--pgvector)
  - [4.3 Redis](#43-redis)
  - [4.4 FastAPI Server](#44-fastapi-server)
- [5. Environment Configuration](#5-environment-configuration)
  - [5.1 .env.example (template, committed)](#51-envexample-template-committed)
  - [5.2 .env (actual values, gitignored)](#52-env-actual-values-gitignored)
  - [5.3 .gitignore Rules](#53-gitignore-rules)
- [6. Docker Compose Setup](#6-docker-compose-setup)
  - [6.1 Production Mode](#61-production-mode)
  - [6.2 Development Mode (Hot Reload)](#62-development-mode-hot-reload)
  - [6.3 docker-compose.yml Breakdown](#63-docker-composeyml-breakdown)
  - [6.4 docker-compose.override.yml Breakdown](#64-docker-composeoverrideyml-breakdown)
- [7. Server Dockerfile](#7-server-dockerfile)
  - [7.1 Multi-stage Build](#71-multi-stage-build)
  - [7.2 .dockerignore](#72-dockerignore)
- [8. Running the Project](#8-running-the-project)
  - [8.1 First Time Setup](#81-first-time-setup)
  - [8.2 Daily Commands](#82-daily-commands)
  - [8.3 Development Workflow](#83-development-workflow)
- [9. Health Checks](#9-health-checks)
- [10. Useful Commands](#10-useful-commands)
- [11. Important Notes](#11-important-notes)
  - [11.1 SSE Streaming Configuration](#111-sse-streaming-configuration)
  - [11.2 Vector Database (pgvector)](#112-vector-database-pgvector)
  - [11.3 Python Version Mismatch](#113-python-version-mismatch)
  - [11.4 App Structure Requirement](#114-app-structure-requirement)
  - [11.5 Inter-Container Communication](#115-inter-container-communication)
  - [11.6 Flutter App Connectivity](#116-flutter-app-connectivity)
- [12. Troubleshooting](#12-troubleshooting)

---

## 1. Project Overview

This project consists of:

| Component | Description |
|-----------|-------------|
| **FastAPI Server** | Backend API with agentic AI support (LangChain/LangGraph), SSE streaming for Lixi chat |
| **PostgreSQL + pgvector** | Main database with vector similarity search for RAG/embeddings |
| **Redis** | Caching, session store, message broker |
| **Nginx** | Reverse proxy with SSE-specific buffering configuration |
| **Flutter App** | Mobile frontend (separate in `app/`) |

Infrastructure runs entirely via Docker Compose.

---

## 2. Prerequisites

Before starting, ensure your system has:

| Tool | Minimum Version | Check |
|------|-----------------|-------|
| **Docker Engine** | 24+ | `docker --version` |
| **Docker Compose** | v2 (plugin) | `docker compose version` |
| **Git** | 2.x | `git --version` |
| **Python** (optional, local dev) | 3.14 | `python --version` |
| **uv** (optional, local dev) | latest | `uv --version` |

> **Python 3.14 Note**: `pyproject.toml` requires `requires-python = ">=3.14"`, while the Dockerfile currently uses `python:3.12-slim`. See [section 11.3](#113-python-version-mismatch).

---

## 3. Project Structure

```
ml_prak/
│
├── infra/                                  # Docker infrastructure
│   ├── docker-compose.yml                  # Production compose
│   ├── docker-compose.override.yml         # Dev mode overrides (hot reload)
│   ├── .env.example                        # Template env (committed to git)
│   ├── .env                                # Actual secrets (git-ignored)
│   ├── nginx/
│   │   └── default.conf                    # Nginx config with SSE support
│   └── postgres/
│       └── init.sql                        # Init extensions (pgvector, etc.)
│
├── server/                                 # FastAPI backend
│   ├── Dockerfile                          # Multi-stage Docker build
│   ├── .dockerignore
│   ├── pyproject.toml                      # Python dependencies
│   ├── uv.lock                             # Lock file (uv)
│   ├── main.py                             # Entry point (stub — needs restructuring)
│   └── app/                                # Target structure (not yet created)
│       ├── main.py                         # FastAPI app instance
│       ├── core/
│       │   ├── config.py
│       │   ├── security.py
│       │   └── exceptions.py
│       ├── db/
│       │   ├── session.py
│       │   └── base.py
│       ├── modules/
│       │   ├── auth/
│       │   ├── book/
│       │   └── user/
│       ├── agents/
│       │   ├── graphs/
│       │   ├── nodes/
│       │   ├── tools/
│       │   ├── prompts/
│       │   ├── state.py
│       │   └── llm.py
│       └── shared/
│           ├── deps.py
│           └── utils.py
│
├── app/                                    # Flutter frontend
│   ├── lib/main.dart
│   ├── pubspec.yaml
│   └── ... (android, ios, web, etc.)
│
├── docs/
│   └── 1_setup_requirement.md              # This file
│
├── .gitignore
└── readme.md
```

---

## 4. Service Descriptions

### 4.1 Nginx (Reverse Proxy)

**File**: `infra/nginx/default.conf`

Nginx acts as the single entry point to the backend. Two location blocks:

| Location | Purpose | Special Config |
|----------|---------|----------------|
| `/` | All general requests | Standard HTTP/1.1 proxy |
| `~* /(stream\|sse\|chat)` | SSE / streaming endpoints | **Buffering disabled** |

**SSE Buffering** (`location ~* /(stream|sse|chat)`):

```nginx
proxy_buffering off;
proxy_cache off;
chunked_transfer_encoding off;
proxy_read_timeout 3600s;
proxy_send_timeout 3600s;
add_header X-Accel-Buffering no;
```

This prevents nginx from holding streaming responses until the buffer is full, which would cause Lixi chat to feel laggy.

### 4.2 PostgreSQL + pgvector

**Image**: `pgvector/pgvector:pg17`  
**Init script**: `infra/postgres/init.sql`

Extensions activated automatically on first container start:

| Extension | Function |
|-----------|----------|
| `vector` | Vector similarity search (RAG / embeddings) |
| `pg_trgm` | Fuzzy string matching (trigram), suitable for hybrid search |
| `uuid-ossp` | Generate UUID at database level |

**Volume**: `pgdata` (persistent, named volume)  
**Health check**: `pg_isready -U <user> -d <db>` (interval 5s, retry 10x)

### 4.3 Redis

**Image**: `redis:7-alpine`  
**Auth**: Password from environment variable `REDIS_PASSWORD`

**Volume**: `redisdata` (persistent, named volume)  
**Health check**: `redis-cli -a <password> ping` (interval 5s, retry 10x)

### 4.4 FastAPI Server

**Build context**: `../server/`  
**Dockerfile**: `server/Dockerfile`  
**Port**: 8000 (only exposed on internal network, except in dev mode)

Depends on `db` and `redis` — both must be healthy (`condition: service_healthy`) before the server starts.

---

## 5. Environment Configuration

### 5.1 .env.example (template, committed)

**File**: `infra/.env.example`

```env
# Postgres
POSTGRES_USER=ml_prak_user
POSTGRES_PASSWORD=change_me_super_secret
POSTGRES_DB=ml_prak_db
POSTGRES_PORT=5432

# Redis
REDIS_PASSWORD=change_me_redis_secret
REDIS_PORT=6379

# FastAPI server
SERVER_PORT=8000

# Nginx
NGINX_PORT=80

# Connection strings (used by server code)
DATABASE_URL=postgresql+asyncpg://ml_prak_user:change_me_super_secret@db:5432/ml_prak_db
REDIS_URL=redis://:change_me_redis_secret@redis:6379/0
```

This file **is committed to git** — it only contains placeholders to inform developers which env vars are needed.

### 5.2 .env (actual values, gitignored)

Copy from template and fill in real credentials:

```bash
cp infra/.env.example infra/.env
# then edit infra/.env with real passwords
```

This file **is not committed** (ignored by `.gitignore`).

### 5.3 .gitignore Rules

```
.env
.env.*
!.env.example
!infra/.env.example
```

- `.env`, `.env.*` → all env files are ignored
- `!.env.example` → except `.env.example` and `infra/.env.example` remain tracked

If `.env` was previously tracked, remove from git index:

```bash
git rm --cached infra/.env
```

---

## 6. Docker Compose Setup

### 6.1 Production Mode

```bash
cd infra
docker compose -f docker-compose.yml up -d --build
```

`docker-compose.override.yml` is **not** read when `-f` is explicitly used.

Alternatively:

```bash
docker compose up -d --build
```

Without `-f`, Compose automatically reads `docker-compose.yml` + `docker-compose.override.yml` (if present).

### 6.2 Development Mode (Hot Reload)

Override is active automatically when running `docker compose up` without `-f`:

```bash
cd infra
docker compose up -d --build
```

Dev mode changes:
- **Server**: source code mounted from host (`../server:/app`), uvicorn uses `--reload`
- **Server port**: 8000 exposed to host (bypass nginx for direct debugging)
- **DB port**: 5432 exposed to host (access via DBeaver, local psql, etc.)
- **Redis port**: 6379 exposed to host (access via local redis-cli)

### 6.3 docker-compose.yml Breakdown

```yaml
name: ml_prak
```

All containers use the `ml_prak` prefix.

**Network**: `ml_prak_net` (bridge driver). All services are on the same network and communicate via **service name** (not localhost).

```yaml
services:
  db:          # accessible by other containers as "db"
  redis:       # accessible as "redis"
  server:      # accessible as "server"
  nginx:       # public entry point on port 80
```

**Depends-on with health check**:

```yaml
depends_on:
  db:
    condition: service_healthy
  redis:
    condition: service_healthy
```

Server will not start until DB and Redis are fully ready to accept connections.

### 6.4 docker-compose.override.yml Breakdown

```yaml
services:
  server:
    volumes:
      - ../server:/app        # Mount source code live
    command: ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]

  db:
    ports:
      - "${POSTGRES_PORT}:5432"   # Expose to host

  redis:
    ports:
      - "${REDIS_PORT}:6379"      # Expose to host
```

This file **does not need to be committed** (optional — can be ignored or committed per team preference).

---

## 7. Server Dockerfile

### 7.1 Multi-stage Build

**File**: `server/Dockerfile`

| Stage | Base Image | Purpose |
|-------|-----------|---------|
| `builder` | `python:3.12-slim` | Install dependencies + compile bytecode |
| `runtime` | `python:3.12-slim` | Final image, non-root user, minimal footprint |

**Builder steps**:

1. Copy UV binary from official image
2. Copy only `pyproject.toml` + `uv.lock` → install dependencies (layer cache)
3. Copy all source code → final sync

**Runtime steps**:

1. Create `appuser` (non-root — security best practice)
2. Copy `/app` from builder
3. Set `PATH` to `.venv/bin` (UV virtual env)
4. Set `PYTHONUNBUFFERED=1` (unbuffered logs)
5. Set `PYTHONDONTWRITEBYTECODE=1` (no `__pycache__` at runtime)
6. **HEALTHCHECK**: curl `/health` every 30 seconds

**CMD**:

```dockerfile
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

> **Note**: This assumes the `server/app/main.py` structure with `app = FastAPI()`. See [section 11.4](#114-app-structure-requirement).

### 7.2 .dockerignore

**File**: `server/.dockerignore`

```
.venv/
__pycache__/
*.pyc
.env
.git/
.pytest_cache/
tests/
*.md
```

These files and directories will not be included in the Docker build context, speeding up builds and keeping the image small.

---

## 8. Running the Project

### 8.1 First Time Setup

```bash
# 1. Clone repository
git clone <repo-url> ~/code/ml_prak
cd ~/code/ml_prak

# 2. Setup environment file
cp infra/.env.example infra/.env
nano infra/.env   # Replace all change_me_* with real passwords

# 3. (Optional) Remove env tracking if previously committed
git rm --cached infra/.env 2>/dev/null || true

# 4. Build and start all services
cd infra
docker compose up -d --build

# 5. Check status
docker compose ps
docker compose logs -f server
```

### 8.2 Daily Commands

```bash
# Start all services
cd ~/code/ml_prak/infra
docker compose up -d

# Stop all services
docker compose down

# Restart a specific service
docker compose restart server

# View logs (follow)
docker compose logs -f -t

# Rebuild image (after dependency changes)
docker compose build server

# Build + restart
docker compose up -d --build server

# Remove all containers + volumes (data lost!)
docker compose down -v
```

### 8.3 Development Workflow

With `docker-compose.override.yml`, source code is mounted live:

```bash
cd ~/code/ml_prak/infra
docker compose up -d --build
```

- Edit code in `server/` → changes take effect immediately (uvicorn auto-reload)
- Access API directly via `http://localhost:8000` (bypass nginx)
- Access API via nginx: `http://localhost:80`
- Connect to DB via `localhost:5432`
- Connect to Redis via `localhost:6379`

---

## 9. Health Checks

### Nginx
Nginx has no separate health check — it only depends-on server.

### PostgreSQL
```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
  interval: 5s
  timeout: 5s
  retries: 10
```

### Redis
```yaml
healthcheck:
  test: ["CMD", "redis-cli", "-a", "${REDIS_PASSWORD}", "ping"]
  interval: 5s
  timeout: 5s
  retries: 10
```

### FastAPI Server
```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1
```

The `/health` endpoint must be available in the application:

```python
@app.get("/health")
def health():
    return {"status": "ok"}
```

---

## 10. Useful Commands

```bash
# Check container status
docker compose ps

# View real-time logs
docker compose logs -f

# Logs for a specific service
docker compose logs -f server
docker compose logs -f db

# Access psql in container
docker compose exec db psql -U ml_prak_user -d ml_prak_db

# Check pgvector extension is active
docker compose exec db psql -U ml_prak_user -d ml_prak_db -c "\dx"

# Check specific vector extension
docker compose exec db psql -U ml_prak_user -d ml_prak_db -c "SELECT * FROM pg_extension;"

# Access redis-cli
docker compose exec redis redis-cli -a '<password>' ping

# Enter server container
docker compose exec server /bin/bash

# Check internal network
docker network inspect ml_prak_ml_prak_net

# Check nginx logs
docker compose logs nginx

# Test server connectivity from another container
docker compose exec nginx curl http://server:8000/health
```

---

## 11. Important Notes

### 11.1 SSE Streaming Configuration

Nginx **must** be specially configured for SSE/streaming endpoints. Without this configuration, streaming responses will be buffered by nginx and only sent to the client when the buffer is full or the connection is closed — causing Lixi chat to feel laggy.

Endpoints affected by this rule (regex `~* /(stream|sse|chat)`):
- `/api/chat/stream`
- `/api/stream/*`
- `/sse/*`
- Any endpoint containing the words stream, sse, or chat

If your streaming endpoints have different paths, update the regex in `infra/nginx/default.conf`.

### 11.2 Vector Database (pgvector)

To use vector columns in SQLModel/SQLAlchemy:

```bash
uv add pgvector
```

```python
from pgvector.sqlalchemy import Vector
from sqlmodel import Field, SQLModel, Column

class Embedding(SQLModel, table=True):
    id: int = Field(primary_key=True)
    embedding: list[float] = Field(sa_column=Column(Vector(1536)))  # dimension depends on embedding model
```

### 11.3 Python Version Mismatch

| File | Python Version |
|------|---------------|
| `server/pyproject.toml` | `requires-python = ">=3.14"` |
| `server/Dockerfile` | `python:3.12-slim` |

One of them must be adjusted. Two options:

**Option A**: Update Dockerfile to Python 3.14

```dockerfile
FROM python:3.14-slim AS builder
FROM python:3.14-slim AS runtime
```

**Option B**: Lower `requires-python` in pyproject.toml

```toml
requires-python = ">=3.12"
```

Recommendation: **Option A** (update Dockerfile) because `pyproject.toml` typically reflects actual package dependency requirements.

### 11.4 App Structure Requirement

Dockerfile `CMD` and `docker-compose.override.yml` assume:

```
server/app/main.py   →   app = FastAPI()
```

Currently `server/main.py` is still a stub. You need to create the `server/app/main.py` structure with:

```python
from fastapi import FastAPI

app = FastAPI(title="ML Prak API")

@app.get("/health")
def health():
    return {"status": "ok"}
```

### 11.5 Inter-Container Communication

Inside the Docker Compose network, containers communicate using **service names**, not `localhost`:

| Connection | Host | Port |
|-----------|------|------|
| Server → DB | `db` | 5432 |
| Server → Redis | `redis` | 6379 |
| Nginx → Server | `server` | 8000 |

This is already handled by `DATABASE_URL` and `REDIS_URL` in `.env`:

```
DATABASE_URL=postgresql+asyncpg://user:pass@db:5432/ml_prak_db
REDIS_URL=redis://:pass@redis:6379/0
```

### 11.6 Flutter App Connectivity

The Flutter app (`app/`) should point to nginx, not directly to the server:

```dart
// In your Flutter code
final baseUrl = 'http://<ip-server>:80';  // via nginx, not port 8000
```

During local development, use the host machine's IP (not `localhost`) because Flutter in emulator/device sees `localhost` as itself.

---

## 12. Troubleshooting

### Container keeps restarting
```bash
docker compose logs db     # Check database logs
docker compose logs redis  # Check redis logs
```
Usually caused by health check failure — ensure passwords in `.env` are correct.

### Port already in use
```bash
# Check what is using the port
sudo lsof -i :80
sudo lsof -i :5432
sudo lsof -i :6379
sudo lsof -i :8000

# Change port in .env
```

### SSE not streaming (data arrives all at once)
Ensure nginx config is correct:

```bash
docker compose exec nginx cat /etc/nginx/conf.d/default.conf
# Verify proxy_buffering off is present in location /(stream|sse|chat)
```

### "relation does not exist" error
pgvector extension not active or init.sql hasn't run. Check:

```bash
docker compose exec db psql -U ml_prak_user -d ml_prak_db -c "\dx"
# vector must be in the list
```

### Permission denied during Docker build
```bash
# Build without cache
docker compose build --no-cache server
```

### FastAPI cannot connect to DB
Ensure health checks are passing:
```bash
docker compose ps
# STATUS column must show "healthy" for db, redis, server
```
