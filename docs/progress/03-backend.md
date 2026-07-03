# Progress — Backend Implementation

## Server Komponen

| Area | Progress | Catatan |
|------|----------|---------|
| Infrastructure (Docker, Nginx, PG, Redis) | ✅ Done | Docker Compose, Nginx WS proxy, PostgreSQL, Redis |
| Backend Core (FastAPI, config, logging, CORS) | ✅ Done | 26 env vars, logging centralized + agent.trace JSON logger, CORS |
| ML Layer (Singleton Predictor) | ✅ Done | Load sekali startup, fail-fast, reconstruct dari config.json |
| LangGraph Agent (ReAct loop) | ✅ Done | supervisor + tools + response_node, bind_tools, @tool decorators |
| Tool Wrappers (rag, predictive, firecrawl) | ✅ Done | LangChain @tool, dispatch via tools_node |
| Nginx WS Proxy | ✅ Done | WebSocket upgrade header + buffering off |
| WebSocket Endpoint | ✅ Done | `/ws/v1/chat` + `/ws/v1/health`, event schemas, heartbeat |
| Schemas (Pydantic v2) | ✅ Done | events, auth, prediction, knowledge |
| Auth Service (JWT + bcrypt + SQLAlchemy) | ✅ Done | login, register, refresh, logout, get_current_user |
| DB Service Layer | ✅ Done | auth_service.py dengan passlib + python-jose |
| Predictions Service | ✅ Done | latest, history, analysis via SQLAlchemy |

## API Routes

| Route | Progress | Catatan |
|-------|----------|---------|
| `GET /health` | ✅ Done | Full implementation |
| `POST /api/v1/chat` | ✅ Done | `run_agent()` via LangGraph |
| `WEBSOCKET /ws/v1/chat` | ✅ Done | Full integration dengan real LangGraph reasoning loop & event streaming |
| `POST /api/v1/auth/register` | ✅ Done | bcrypt + JWT, return access+refresh token |
| `POST /api/v1/auth/login` | ✅ Done | bcrypt verify + JWT, return access+refresh token |
| `POST /api/v1/auth/refresh` | ✅ Done | Rotate refresh token, revoke old |
| `POST /api/v1/auth/logout` | ✅ Done | Revoke all refresh tokens |
| `GET /api/v1/auth/me` | ✅ Done | Current user from JWT |
| `GET /api/v1/users/me` | ✅ Done | Current user info |
| `GET /api/v1/users/stats` | ✅ Done | Conversation count, prediction stats |
| `GET /api/v1/predictions/latest` | ✅ Done | Latest prediction from DB |
| `GET /api/v1/predictions/history` | ✅ Done | Paginated history |
| `GET /api/v1/predictions/analysis` | ✅ Done | Aggregated stats (pass rate, avg prob) |
| `POST /api/v1/knowledge/upload` | ✅ Done | SQLAlchemy insert + background ingestion (parse, chunk, embed, pgvector) |
| `GET /api/v1/knowledge/{id}` | ✅ Done | Single document detail |
| `GET /api/v1/knowledge` | ✅ Done | List with filter (status, search) + pagination |
| `DELETE /api/v1/knowledge/{id}` | ✅ Done | Delete doc + chunks + upload dir |

## Komponen Pending

| Area | Progress | Catatan |
|------|----------|---------|
| Auth — Reset password | ⬜ Pending | Belum ada endpoint |
| Auth — Email verification | ⬜ Pending | Belum ada |
| Role-based access control | 🔧 Partial | Cek role di knowledge upload saja |
| Background jobs (Celery/ARQ) | ⬜ Pending | Masih pakai BackgroundTasks |
