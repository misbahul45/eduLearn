# Progress — Backend Implementation

## Server Komponen

| Area | Progress | Catatan |
|------|----------|---------|
| Infrastructure (Docker, Nginx, PG, Redis) | ✅ Done | Docker Compose, Nginx WS proxy, PostgreSQL, Redis |
| Backend Core (FastAPI, config, logging, CORS) | ✅ Done | 26 env vars, logging centralized, CORS |
| ML Layer (Singleton Predictor) | ✅ Done | Load sekali startup, fail-fast, reconstruct dari config.json |
| LangGraph Agent (ReAct loop) | ✅ Done | supervisor + tools + response_node, bind_tools, @tool decorators |
| Tool Wrappers (rag, predictive, firecrawl) | ✅ Done | LangChain @tool, dispatch via tools_node |
| Nginx WS Proxy | ✅ Done | WebSocket upgrade header + buffering off |
| WebSocket Endpoint | ✅ Done | `/ws/v1/chat` + `/ws/v1/health`, event schemas, heartbeat |
| Schemas (Pydantic v2) | ✅ Done | events, auth, prediction (ClassScore, PredictionResult, StudentSignals), knowledge (CitationMeta, Citation) |

## API Routes

| Route | Progress | Catatan |
|-------|----------|---------|
| `GET /health` | ✅ Done | Full implementation |
| `POST /api/v1/chat` | ✅ Done | `run_agent()` via LangGraph |
| `WEBSOCKET /ws/v1/chat` | 🔧 Partial | Accept + ping/pong, masih return dummy response |
| `POST /api/v1/auth/*` | ⬜ Pending | Stub — return 501 |
| `GET /api/v1/users/*` | ⬜ Pending | Stub — return 501 |
| `GET /api/v1/predictions/*` | ⬜ Pending | Stub — return 501 |
| `POST /api/v1/knowledge/upload` | ⬜ Pending | Stub — return 501 |

## Komponen Pending

| Area | Progress | Catatan |
|------|----------|---------|
| RAG + pgvector | 🔧 Partial | vectorstore (DDL + HNSW) + retriever (embed + cosine search) implemented. Ingestion masih stub. |
| Auth JWT | ⬜ Pending | Stub endpoints + contract defined |
| File Upload | ⬜ Pending | Stub endpoint + contract defined |
| Firecrawl Tool | ⬜ Pending | Stub function + contract defined |
