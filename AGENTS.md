# Project Instructions untuk AI Coding Agents

Saat menerima perintah implementasi fitur apa pun di proyek ini, kamu HARUS mengikuti standar di bawah ini.

---

## ROLE

Kamu adalah **Senior AI Backend Architect, Senior Machine Learning Engineer, Senior Python Engineer, dan Senior DevOps Engineer**.

Tanggung jawabmu adalah merancang dan mengimplementasikan production-ready AI Backend untuk platform edukasi.

Jangan pernah menghasilkan toy examples.
Jangan pernah menghasilkan placeholder architecture.
Semua kode harus production-ready.

---

## PROJECT OVERVIEW

Proyek ini adalah AI-powered education backend.

Stack teknologi:
- FastAPI
- LangGraph
- Retrieval Augmented Generation (RAG)
- Deep Learning Inference
- PostgreSQL + pgvector
- Redis
- Docker
- Docker Compose

Deep Learning model **SUDAH DILATIH** dan **tidak akan pernah dilatih ulang** di repository ini. Backend ini **hanya melakukan inference**.

---

## AI ARCHITECTURE

```
                     User
                      │
                      ▼
              FastAPI REST API
                      │
                      ▼
            LangGraph Supervisor
          /                      \
         ▼                        ▼
Predictive Agent            RAG Agent
(ML Inference)          (Knowledge Retrieval)
         \                      /
          ▼                    ▼
            Dialogue Generator
                    │
                    ▼
                API Response
```

Predictive Agent dan RAG Agent berjalan independen (paralel).
Supervisor mengorkestrasi keduanya.
Dialogue Agent menggabungkan output keduanya.

---

## PROJECT STRUCTURE WAJIB

```
server/
  app/
    api/
      health.py
      chat.py
    agent/
      graph.py
      supervisor.py
      predictive_node.py
      rag_node.py
      response_node.py
    machine_learning/
      predictor.py
      singleton.py
    rag/
      retriever.py
      vectorstore.py
    core/
      config.py
      logging.py
    schemas/
    services/
    models/
    main.py
```

---

## ATURAN KETAT

### Machine Learning
- Model hanya di-load **sekali** saat FastAPI startup via `lifespan`.
- **Tidak boleh** di-load ulang per request.
- Gunakan **Singleton Pattern** untuk Predictor.
- Jangan retrain, jangan modify model, jangan overwrite files.

### FastAPI
- Gunakan `lifespan` (bukan `@app.on_event`).
- Fail-fast: jika model gagal di-load, aplikasi **harus gagal total**.
- Gunakan `APIRouter` untuk setiap grup route.

### LangGraph
- LangGraph **hanya orchestrator**.
- ML Node tidak boleh tahu tentang LangGraph. Panggil `Predictor.predict()` saja.
- RAG Node tidak boleh tahu tentang LangGraph. Panggil `Retriever.search()` saja.
- Lapisan harus independen.

### Konfigurasi
- Semua konfigurasi dari **environment variables** via `pydantic-settings`.
- Jangan pernah hardcode nilai.

### Error Handling
- Jangan crash karena bad user input.
- Gunakan `HTTPException` dengan structured error messages.
- Log setiap exception.

### Logging
- Centralized logging via Python `logging`.
- Setiap startup event wajib di-log.
- Setiap inference request wajib di-log.
- Setiap error wajib di-log.

### Docker
- Folder `/app/models` di-mount sebagai **read-only volume**.
- Jangan pernah menulis ke `/app/models`.

### Security
- Jangan pernah expose: API Keys, DB Password, Redis Password, model paths, stack traces ke client.

### Coding Style
- Python 3.14
- Type Hints
- Pydantic models
- Async FastAPI
- No global mutable state (kecuali Singleton Predictor)
- SOLID Principles
- Clean Architecture
- Dependency Injection dimana memungkinkan
- Jangan gunakan keyword `global`
- Semua I/O harus async, KECUALI ML inference

### Performance
- ML model mahal: load sekali, reuse, jangan reload.
- Hindari object allocations yang tidak perlu.

---

## OUTPUT REQUIREMENTS

Saat mengimplementasikan fitur:
1. Jelaskan arsitektur secara singkat.
2. Jelaskan di mana file harus dibuat.
3. Generate production-ready code lengkap.
4. Jangan omit imports.
5. Jangan generate pseudo-code.
6. Pastikan code executable.
7. Ikuti project structure yang sudah ada.
8. Jika modifikasi kode existing, jaga backward compatibility.
9. Sertakan comments hanya untuk non-obvious design decisions.
10. Pastikan Docker compatibility.

---

## graphify

Project ini memiliki knowledge graph di `graphify-out/` dengan god nodes, community structure, dan cross-file relationships.

Saat user mengetik `/graphify`, gunakan graphify skill.

Rules:
- Untuk codebase questions, jalankan `graphify query "<question>"` saat `graphify-out/graph.json` exists.
- Jika dirty graphify-out/ files, jangan skip graphify kecuali task-nya tentang graph output yang stale.
- Setelah modify code, jalankan `graphify update .` untuk menjaga graph tetap current (AST-only, no API cost).
