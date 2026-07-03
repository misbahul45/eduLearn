# Progress — Milestones

| # | Milestone | Target | Status |
|---|-----------|--------|--------|
| 1 | Infra + Docker setup | - | ✅ |
| 2 | Flutter design system + routing | - | ✅ |
| 3 | Server backend architecture | - | ✅ |
| 4 | API contracts + schemas | - | ✅ |
| 5 | ML layer + Predictor singleton | - | ✅ |
| 6 | LangGraph agent ReAct loop | - | ✅ |
| 7 | Auth (JWT) + User API | - | ✅ |
| 8 | WebSocket chat streaming + Flutter UI | - | ✅ |
| 9 | RAG + pgvector search | - | ✅ |
| 10 | File upload + knowledge ingestion | - | ✅ |
| 11 | Flutter pages (all 8 pages) | - | ✅ |
| 12 | Firecrawl web search | - | ✅ |
| 13 | Observability & EventSanitizer | - | ✅ |
| 14 | Deployment & Nginx WS config | - | ✅ |
| 15 | DB Models + SQLAlchemy (9 tables) | - | ✅ |
| 16 | Integration test + deployment | TBD | ⬜ |

## Detail

- **Auth**: Login (bcrypt + JWT access/refresh), register, refresh, logout, me
- **Flutter**: Splash, Login, Register, Home (4 tabs: Chat/Analisis/Materi/Profil), Knowledge
- **RAG**: file upload → parse (PyMuPDF/docx) → chunk (tiktoken 500) → embed (OpenAI) → pgvector (cosine + HNSW)
- **WebSocket**: Integrasi penuh dengan real LangGraph reasoning loop, streaming tokens & trace events, JWT auth + rate limiting + heartbeat.
