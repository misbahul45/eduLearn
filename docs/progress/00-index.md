# Progress Tracking — Index

Folder ini berisi status implementasi tiap area proyek EduLearn AI.

## Cara Membaca

- ✅ = **Done** — selesai, sudah terintegrasi
- 🔧 = **Partial** — sebagian jadi, sebagian masih stub/pending
- ⬜ = **Pending** — belum dimulai, hanya kontrak/doc

## Ringkasan

| Area | Progress | Prioritas |
|------|----------|-----------|
| Dokumentasi spesifikasi | ✅ 17/18 docs | Selesai |
| Planning DB | ✅ 3/3 docs | docs/planning/ |
| DB Models (SQLAlchemy) | ✅ 9 tabel | server/app/db/ |
| Kontrak API | ✅ 7/7 docs | Selesai |
| Backend core | ✅ Done | - |
| ML Inference | ✅ Done | - |
| LangGraph Agent | ✅ Done | - |
| Auth API (JWT + bcrypt + SQLAlchemy) | ✅ Done | Login, register, refresh, logout, me |
| Users API | ✅ Done | Profile + stats |
| Predictions API | ✅ Done | Latest, history, analysis |
| RAG + pgvector + Knowledge Upload | ✅ Done | Upload + ingestion pipeline |
| Flutter App — Landing Pages | ✅ Done | Splash, Login, Register dengan Riverpod |
| Flutter App — Main Pages | ✅ Done | Home (4 tabs), Chat, Analysis, Knowledge, Profile |
| Firecrawl Tool | ✅ Done | Selesai |
| Observability & EventSanitizer | ✅ Done | Selesai |
| Input Tool Validation & Audit DDL | ✅ Done | Selesai |

## File Index

| # | File | Isi |
|---|------|-----|
| 01 | `01-specification.md` | Status per-file dokumen spesifikasi (00–18) |
| 02 | `02-contract.md` | Status per-file kontrak API (01–07) |
| 03 | `03-backend.md` | Status implementasi backend per komponen |
| 04 | `04-flutter.md` | Status implementasi Flutter per halaman |
| 05 | `05-milestone.md` | Milestone dan target rilis |
