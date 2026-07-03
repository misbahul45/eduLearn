# Planning — DB Models

## Struktur

```
server/app/db/
  __init__.py              ← engine, async_session, Base, get_db
  models/
    __init__.py
    user.py
    conversation.py
    knowledge.py
    prediction.py
    audit.py
  migrations/
    run.py
```

## 9 Tabel

| # | Tabel | Domain | File Model |
|---|-------|--------|------------|
| 1 | `users` | Auth | `user.py` |
| 2 | `refresh_tokens` | Auth | `user.py` |
| 3 | `conversations` | Chat | `conversation.py` |
| 4 | `messages` | Chat | `conversation.py` |
| 5 | `knowledge_documents` | RAG | `knowledge.py` |
| 6 | `knowledge_chunks` | RAG | `knowledge.py` |
| 7 | `prediction_histories` | ML | `prediction.py` |
| 8 | `audit_conversations` | Audit | `audit.py` |
| 9 | `audit_uploads` | Audit | `audit.py` |

## Relasi

```
users
  ├── 1:N ── refresh_tokens (CASCADE)
  ├── 1:N ── conversations
  ├── 1:N ── prediction_histories
  ├── 1:N ── knowledge_documents
  ├── 1:N ── audit_conversations
  └── 1:N ── audit_uploads

conversations
  ├── 1:N ── messages (CASCADE)
  └── 1:N ── prediction_histories (SET NULL)

knowledge_documents
  ├── 1:N ── knowledge_chunks (CASCADE)
  └── 1:N ── audit_uploads
```

## Migration

`python -m app.db.migrations.run` → `Base.metadata.create_all`

## Update File Lain

- `infra/postgres/init.sql` → hanya `CREATE EXTENSION`
- `server/app/rag/vectorstore.py` → refactor pakai SQLAlchemy model
