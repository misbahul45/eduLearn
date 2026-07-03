# Spesifikasi Sistem — Index

Folder ini berisi dokumen spesifikasi sistem EduLearn AI. Bacalah secara berurutan untuk memahami sistem secara utuh.

## Daftar Dokumen

| # | File | Isi |
|---|------|-----|
| 01 | `01-overview.md` | Tujuan sistem, value proposition, komponen tingkat tinggi, wireframe alur tipikal |
| 02 | `02-design-system.md` | Palet warna, spacing, tipografi, routing Flutter, state management Riverpod, konvensi backend |
| 03 | `03-architecture.md` | Arsitektur high-level, diagram, komponen infrastruktur, transport layer, data flow |
| 04 | `04-agent-orchestration.md` | LangGraph ReAct loop, node (supervisor/tools/response), AgentState, edge conditional |
| 05 | `05-rag-knowledge.md` | RAG system: pgvector schema, retrieval flow, citation format, tampilan Flutter |
| 06 | `06-ml-prediction.md` | ML binary classification: dataset, feature engineering, arsitektur Deep MLP, artifacts, inference flow |
| 07 | `07-firecrawl-tool.md` | Web search tool via Firecrawl API: endpoint, caching, sanitasi |
| 08 | `08-observability.md` | Logging, tracing, monitoring: EventSanitizer, agent.trace JSON logger |
| 09 | `09-deployment.md` | Deployment, Docker, Nginx reverse proxy + WS config, environment variables |
| 10 | `10-security.md` | JWT, rate limiting (token bucket Redis), sanitasi input, audit log |
| 11 | `11-file-upload.md` | File upload & knowledge ingestion pipeline: parse, chunk, embed, pgvector insert |
| 12 | `12-flutter-splash.md` | Splash page Flutter: Riverpod ViewModel, auto-routing (login/home) |
| 13 | `13-login.md` | Login page: ViewModel, AuthRepository, secure storage, error handling |
| 14 | `14-register.md` | Register page: ViewModel, AuthRepository, secure storage, validation |
| 15 | `15-home.md` | Home dashboard: StatefulShellRoute, greeting, prediction summary, fl_chart history, quick actions |
| 16 | `16-chat.md` | Chat UI: realtime WS agent, streaming tokens, AgentTraceSheet, prediction chart, citations, web search |
| 17 | `17-analysis.md` | Analysis page: donut chart distribusi, strength/improvement cards, recommendations, progress comparison, history list |
| 18 | `18-profile.md` | Profile page: biodata, stats, knowledge management (pengajar), upload sheet, settings, logout |
