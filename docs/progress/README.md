# Progress Tracking — EduLearn AI

> File ini adalah index utama progress implementasi. Update setiap ada perubahan signifikan.

## Status Proyek

| Area | Progress | Catatan |
|------|----------|---------|
| Infrastructure | ✅ Done | Docker Compose, Nginx (WS proxy), PostgreSQL, Redis |
| Backend Core | ✅ Done | FastAPI, config (26 vars), logging, CORS, health |
| ML Layer | ✅ Done | Singleton, Predictor, model loading (fail-fast) |
| LangGraph Agent | 🔧 Partial | Graph & nodes done, ReAct loop re-wire pending |
| Tool Wrappers | ✅ Done | `rag_tool`, `predictive_tool`, `firecrawl_tool` created |
| Nginx WS Proxy | ✅ Done | WebSocket upgrade header + buffering off |
| API Routes | 🔧 Partial | health ✅, chat REST ✅, chat WS ✅, auth ⬜, users ⬜, predictions ⬜, knowledge ⬜ |
| WebSocket | ✅ Done | Endpoint + event schemas + contract defined |
| Schemas | ✅ Done | events, auth, prediction, knowledge, chat, health |
| RAG (pgvector) | ⬜ Pending | Placeholder created |
| File Upload | ⬜ Pending | Stub endpoint + contract defined |
| Auth (JWT) | ⬜ Pending | Stub endpoints + contract defined |
| Firecrawl Tool | ⬜ Pending | Stub function + contract defined |
| API Contracts | ✅ Done | health, auth, users, predictions, knowledge, chat WS |
| Flutter App | 🔧 Partial | Design system ✅, routing ✅, pages ⬜ |

## Milestones

| # | Milestone | Target | Status |
|---|-----------|--------|--------|
| 1 | Infra + Docker setup | - | ✅ |
| 2 | Flutter design system + routing | - | ✅ |
| 3 | Server backend architecture | - | ✅ |
| 4 | API contracts + schemas | - | ✅ |
| 5 | Auth (JWT) + User API | TBD | ⬜ |
| 6 | WebSocket chat + agent ReAct loop | TBD | ⬜ |
| 7 | RAG + pgvector | TBD | ⬜ |
| 8 | File upload + knowledge ingestion | TBD | ⬜ |
| 9 | Flutter pages (login, home, chat, analysis, profile) | TBD | ⬜ |
| 10 | Integration test + deployment | TBD | ⬜ |

## Files

### Design Docs (`docs/`)

| # | File | Status |
|---|------|--------|
| 00 | `00-design-system.md` | ✅ |
| 01 | `01-overview.md` | ✅ |
| 02 | `02-architecture.md` | ✅ |
| 03 | `03-agent-orchestration.md` | ⬜ |
| 04 | `04-websocket-events.md` | ⬜ |
| 05 | `05-rag-knowledge.md` | ⬜ |
| 06 | `06-ml-prediction.md` | ⬜ |
| 07 | `07-firecrawl-tool.md` | ⬜ |
| 08 | `08-logging-observability.md` | ⬜ |
| 09 | `09-deployment.md` | ⬜ |
| 10 | `10-security.md` | ⬜ |
| 11 | `11-file-upload-api.md` | ⬜ |
| 12 | `12-flutter-splash.md` | ⬜ |
| 13 | `13-flutter-login.md` | ⬜ |
| 14 | `14-flutter-register.md` | ⬜ |
| 15 | `15-flutter-home.md` | ⬜ |
| 16 | `16-flutter-chat.md` | ⬜ |
| 17 | `17-flutter-analysis.md` | ⬜ |
| 18 | `18-flutter-profile.md` | ⬜ |

### Progress Tracking (`docs/progress/`)

| File | Status |
|------|--------|
| `README.md` | ✅ |

### API Contracts (`docs/contract/`)

| File | Status |
|------|--------|
| `README.md` | ✅ |
| `01-health.md` | ✅ |
| `02-auth.md` | ✅ |
| `03-users.md` | ✅ |
| `04-predictions.md` | ✅ |
| `05-knowledge.md` | ✅ |
| `06-chat-ws.md` | ✅ |
