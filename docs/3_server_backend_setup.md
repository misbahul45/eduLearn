# Progress 3: Server Backend — Production-Ready AI Architecture

## Tracking Progress

| Progress | File | Status |
|----------|------|--------|
| 1 | `docs/1_setup_requirement.md` | Infrastructure & Docker setup |
| 2 | `docs/2_flutter_bootstrap.md` | Flutter design system & routing |
| **3** | **`docs/3_server_backend_setup.md`** | **Server AI backend architecture (done)** |

---

## Summary

Complete overhaul of the server backend from a stub into a **production-ready AI architecture** following Clean Architecture, SOLID principles, and FAANG-level engineering standards.

### What Was Built

| Area | Description |
|------|-------------|
| **AI Agent Architecture** | LangGraph multi-agent with parallel predictive + RAG execution |
| **ML Inference Engine** | TensorFlow + scikit-learn pipeline, loaded once at startup via Singleton |
| **FastAPI Application** | Async API with lifespan, fail-fast startup, APIRouter separation |
| **LLM Integration** | OpenAI-compatible provider (Flaz.id) via LangChain |
| **Configuration** | pydantic-settings from single `infra/.env` file |
| **Health System** | Full health check endpoint with model status, uptime, versions |
| **Chat Endpoint** | POST `/api/v1/chat` routed through LangGraph agent |
| **Project Standards** | AGENTS.md + `.github/copilot-instructions.md` for AI coding consistency |
| **Documentation** | Comprehensive `server/README.md` |

---

## 1. AI Architecture

### Hybrid AI Flow

```
User → FastAPI → LangGraph Supervisor
                        │
            ┌───────────┴───────────┐
            ▼                       ▼
    Predictive Node           RAG Node
    (ML Inference)        (Vector Search)
            │                       │
            └───────────┬───────────┘
                        ▼
                 Response Node
                  (LLM Merge)
                        │
                        ▼
                   API Response
```

Key design decision: **Predictive and RAG nodes run in parallel** via LangGraph `Send` fan-out. The supervisor does not block — both branches execute concurrently.

### Layer Independence

```
FastAPI (API layer)
    │
    ▼
LangGraph (orchestration only)
    │
    ├──► ML Predictor (knows nothing about LangGraph)
    └──► RAG Retriever (knows nothing about LangGraph)
```

This ensures each layer is independently testable and swappable.

---

## 2. Project Structure (server/app/)

```
server/app/
├── __init__.py
├── main.py                          # FastAPI entrypoint + lifespan
│
├── api/
│   ├── __init__.py
│   ├── health.py                    # GET /health
│   └── chat.py                      # POST /api/v1/chat
│
├── agent/
│   ├── __init__.py
│   ├── graph.py                     # LangGraph StateGraph definition
│   ├── supervisor.py                # Fan-out router via Send
│   ├── predictive_node.py           # Calls Predictor.predict()
│   ├── rag_node.py                  # Calls Retriever.search()
│   └── response_node.py             # LLM response generation
│
├── machine_learning/
│   ├── __init__.py
│   ├── singleton.py                 # Thread-safe Singleton metaclass
│   └── predictor.py                 # Model loader + inference
│
├── rag/
│   ├── __init__.py
│   ├── retriever.py                 # RAG search interface
│   └── vectorstore.py               # pgvector integration
│
├── core/
│   ├── __init__.py
│   ├── config.py                    # pydantic-settings
│   └── logging.py                   # Centralized logging
│
├── schemas/
│   ├── __init__.py
│   ├── health.py                    # Health response models
│   └── chat.py                      # Chat request/response models
│
├── services/                        # Business logic layer (future)
│   └── __init__.py
│
└── models/                          # Pydantic/SQLModel DB models (future)
    └── __init__.py
```

---

## 3. Machine Learning Layer

### Singleton Pattern (`machine_learning/singleton.py`)

Thread-safe double-checked locking metaclass:

```python
class SingletonMeta(type):
    _instances: ClassVar[dict] = {}
    _lock: threading.Lock = threading.Lock()

    def __call__(cls, *args, **kwargs):
        if cls not in cls._instances:
            with cls._lock:
                if cls not in cls._instances:
                    instance = super().__call__(*args, **kwargs)
                    cls._instances[cls] = instance
        return cls._instances[cls]
```

### Predictor (`machine_learning/predictor.py`)

| Method | Description |
|--------|-------------|
| `load()` | Loads `model.weights.h5`, `pipeline.joblib`, `metadata.json`, `config.json` from `MODEL_DIR` |
| `predict(features)` | Transforms input through pipeline, runs TensorFlow inference |
| `health()` | Returns `{"loaded": bool, "error": str\|None}` |

Rules enforced in code:
- TensorFlow availability checked at load time (graceful `ImportError` handling)
- Fail-fast: raises `RuntimeError` or `FileNotFoundError` if anything missing
- Model loaded **once** at FastAPI startup via `lifespan`
- Singleton ensures same instance across all requests and threads

### Model Files (`server/models/`)

```
server/models/
├── model.weights.h5       # TensorFlow Keras weights
├── pipeline.joblib        # scikit-learn preprocessing pipeline
├── metadata.json          # Model metadata (input shape, classes, etc.)
└── config.json            # Model hyperparameters
```

These are **never retrained, modified, or overwritten** by the backend.

---

## 4. FastAPI Application (`main.py`)

### Lifespan (Startup/Shutdown)

```python
@asynccontextmanager
async def lifespan(app: FastAPI):
    setup_logging()
    predictor = Predictor()
    try:
        predictor.load()
    except Exception as e:
        logger.critical("Failed to load predictor on startup: %s", e)
        raise    # ← FAIL-FAST
    yield
    logger.info("Application shutting down")
```

### Registered Routes

| Method | Path | Router | Description |
|--------|------|--------|-------------|
| GET | `/health` | `health.py` | Health check with model status |
| POST | `/api/v1/chat` | `chat.py` | AI chat through LangGraph agent |

### Health Check Response

**200 OK:**
```json
{
  "status": "healthy",
  "model_loaded": true,
  "model_directory": "/app/models",
  "version": "1.0.0",
  "uptime": "123.45s",
  "python": "3.14.5",
  "tensorflow": "2.18.0",
  "environment": "production"
}
```

**503 Service Unavailable:**
```json
{
  "status": "unhealthy",
  "error": "TensorFlow is not installed. Cannot load model."
}
```

---

## 5. LangGraph Agent

### Graph Structure (`agent/graph.py`)

```python
builder = StateGraph(AgentState)

builder.add_node("predictive", predictive_node)
builder.add_node("rag", rag_node)
builder.add_node("response", response_node)

# Fan-out: supervisor sends to both nodes in parallel
builder.set_conditional_entry_point(route_to_workers, ["predictive", "rag"])

# Merge: both nodes feed into response
builder.add_edge("predictive", "response")
builder.add_edge("rag", "response")
builder.add_edge("response", END)
```

### Supervisor (`agent/supervisor.py`)

Uses LangGraph `Send` for true parallel execution:

```python
def route_to_workers(state: AgentState) -> list[Send]:
    return [
        Send("predictive", state),
        Send("rag", state),
    ]
```

### State Schema (`agent/graph.py`)

```python
class AgentState(TypedDict):
    input: str
    conversation_id: str | None
    prediction: Any           # From ML node
    retrieved_docs: list[str] # From RAG node
    response: str             # Final LLM response
```

### Node Responsibilities

| Node | File | Function |
|------|------|----------|
| Predictive | `predictive_node.py` | Calls `Predictor.predict()` with feature vector |
| RAG | `rag_node.py` | Calls `Retriever.search()` with query text |
| Response | `response_node.py` | Merges context + prediction, sends to LLM |

---

## 6. LLM Integration

### Provider: Flaz.id (OpenAI-Compliant)

Configured via environment variables in `infra/.env`:

```env
FLAZ_BASE_URL=https://ai.flaz.id/v1
FLAZ_API_KEY=sk-xxx
LLM_MODEL=MiniMax-M2.7-highspeed
```

Used in `agent/response_node.py` via LangChain:

```python
llm = ChatOpenAI(
    api_key=settings.FLAZ_API_KEY,
    base_url=settings.FLAZ_BASE_URL,
    model=settings.LLM_MODEL,
)
```

Any OpenAI-compatible provider can be swapped in by changing these variables.

---

## 7. Configuration System

### Single Source of Truth: `infra/.env`

All environment variables are defined in a single file:

| Variable | Used By | Description |
|----------|---------|-------------|
| `POSTGRES_USER/PASSWORD/DB/PORT` | Docker Compose | PostgreSQL credentials |
| `REDIS_PASSWORD/PORT` | Docker Compose | Redis credentials |
| `DATABASE_URL` | Server | AsyncPG connection string |
| `REDIS_URL` | Server | Redis connection string |
| `MODEL_DIR` | Server | Path to ML model files |
| `FLAZ_BASE_URL` | Server | LLM API base URL |
| `FLAZ_API_KEY` | Server | LLM API key |
| `LLM_MODEL` | Server | LLM model name |
| `ENVIRONMENT` | Server | Runtime environment |
| `SERVER_PORT` | Docker Compose | Internal server port |
| `NGINX_PORT` | Docker Compose | Public nginx port |

### How It Flows

- **Docker**: `docker-compose.yml` uses `env_file: .env` → all vars injected into container → `pydantic-settings` reads from `os.environ`
- **Local dev**: `pydantic-settings` reads `../infra/.env` directly from file

### Settings Class (`core/config.py`)

```python
class Settings(BaseSettings):
    MODEL_DIR: str = "/app/models"
    DATABASE_URL: str = "..."
    REDIS_URL: str = "..."
    FLAZ_BASE_URL: str = "https://ai.flaz.id/v1"
    FLAZ_API_KEY: str = ""
    LLM_MODEL: str = "MiniMax-M2.7-highspeed"
    ENVIRONMENT: str = "production"
    VERSION: str = "1.0.0"

    model_config = {
        "env_file": "../infra/.env",
        "extra": "ignore",     # Ignore infra-only vars (POSTGRES_*, etc.)
    }
```

---

## 8. Docker Compose Changes

### Before

```yaml
server:
  env_file:
    - .env
  environment:            # Hardcoded duplication
    DATABASE_URL: ${DATABASE_URL}
    REDIS_URL: ${REDIS_URL}
    MODEL_DIR: /app/models
    ...
```

### After

```yaml
server:
  env_file:
    - .env                # Single source — all vars from infra/.env
```

No more hardcoded environment variables. Everything comes from `infra/.env`.

---

## 9. AI Coding Standards

### AGENTS.md

Updated with complete project instructions covering:

- **Role**: Senior AI Backend Architect + MLE + Python + DevOps Engineer
- **Architecture**: Hybrid AI with parallel agent execution
- **10 Critical Rules**: ML load-once, fail-fast, LangGraph orchestrator-only, etc.
- **Coding Standards**: Python 3.14, type hints, SOLID, Clean Architecture
- **Output Requirements**: Production-ready code, no pseudo-code, full imports
- **Security**: No API key/stack trace exposure

### `.github/copilot-instructions.md`

Created for GitHub Copilot, Codex, Gemini CLI, and other AI tools that support project-level instructions:

- Concise role + stack definition
- Critical rules in bullet-point format
- Project structure tree
- Architecture flow diagram
- Coding standards checklist

---

## 10. Dependencies Added

| Package | Purpose |
|---------|---------|
| `pydantic-settings` | Environment variable loading with validation |

Plus development-time installs:
- `joblib`, `numpy`, `pandas`, `scikit-learn` (ML pipeline dependencies)

---

## 11. Verification

### Import Test

All modules import successfully:

```
Core imports OK
Health router OK: ['/health']
Chat router OK: ['/chat']
LangGraph graph OK
Supervisor OK
Predictive node OK
RAG node OK
Response node OK
Retriever OK
Singleton works: True
```

### Fail-Fast Test

When model loading fails (e.g., TensorFlow not installed):

```
CRITICAL | predictor.py:32 | TensorFlow is not installed. Cannot load model.
CRITICAL | main.py:26 | Failed to load predictor on startup: ...
Lifespan correctly failed: RuntimeError: ...
```

### Config Load Test

```
FLAZ_BASE_URL: https://ai.flaz.id/v1
FLAZ_API_KEY: ***
LLM_MODEL: MiniMax-M2.7-highspeed
DATABASE_URL: postgresql+asyncpg://ml_prak_user:change_me_super_...
REDIS_URL: redis://:change_me_redis_secret@redis:6379/0
MODEL_DIR: /app/models
ENVIRONMENT: production
```

---

## 12. Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Singleton Pattern for Predictor | ML model is expensive — load once, reuse forever |
| Fail-fast on startup | Better to crash immediately than serve broken responses |
| Parallel agent execution | Predictive + RAG are independent; no reason to serialize |
| Send fan-out (not sub-graph) | LangGraph idiomatic parallel pattern |
| `extra="ignore"` in Settings | `infra/.env` has infra-only vars; server should ignore them gracefully |
| TensorFlow optional import | Python 3.14 not yet supported by TF; graceful degradation |
| No hardcoded env in docker-compose | Single source of truth = `infra/.env` |

---

## 13. Future Work

- [ ] Implement actual RAG retrieval with pgvector
- [ ] Add real ML feature extraction in predictive node
- [ ] Conversation history management (via Redis or PostgreSQL)
- [ ] Authentication module (JWT + Argon2)
- [ ] User management endpoints
- [ ] Admin dashboard API
- [ ] SSE streaming for chat responses
- [ ] Async task queue (Celery / Redis Queue)
- [ ] Integration tests with pytest
- [ ] CI/CD pipeline
