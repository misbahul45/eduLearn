# EduLearn AI Backend

Production-ready AI backend for educational platform with FastAPI, LangGraph, RAG, and Deep Learning inference.

## Architecture

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

Predictive Agent (ML inference) and RAG Agent (vector search) execute **in parallel**.  
Supervisor orchestrates both via LangGraph `Send` fan-out.  
Response Agent merges outputs and generates final answer via LLM.

## Tech Stack

| Layer | Technology |
|---|---|
| API Framework | FastAPI (async) |
| Orchestration | LangGraph |
| ML Inference | TensorFlow + scikit-learn pipeline |
| RAG | pgvector (PostgreSQL) |
| LLM | OpenAI-compatible API via LangChain |
| Config | pydantic-settings (env vars) |
| Database | PostgreSQL 17 + pgvector |
| Cache | Redis 7 |
| Container | Docker + Docker Compose |
| Proxy | Nginx |
| Language | Python 3.14 |
| Package | uv |

## Project Structure

```
server/
├── app/
│   ├── api/
│   │   ├── health.py          # GET /health
│   │   └── chat.py            # POST /api/v1/chat
│   ├── agent/
│   │   ├── graph.py            # LangGraph StateGraph definition
│   │   ├── supervisor.py       # Fan-out router (parallel Send)
│   │   ├── predictive_node.py  # Calls Predictor.predict()
│   │   ├── rag_node.py         # Calls Retriever.search()
│   │   └── response_node.py    # LLM response generation
│   ├── machine_learning/
│   │   ├── singleton.py        # Thread-safe Singleton metaclass
│   │   └── predictor.py        # Model loader + inference
│   ├── rag/
│   │   ├── retriever.py        # RAG search interface
│   │   └── vectorstore.py      # pgvector integration
│   ├── core/
│   │   ├── config.py           # pydantic-settings
│   │   └── logging.py          # Centralized logging
│   ├── schemas/
│   │   ├── health.py           # Health response models
│   │   └── chat.py             # Chat request/response models
│   ├── services/               # Business logic layer
│   ├── models/                 # Pydantic/SQLModel DB models
│   └── main.py                 # FastAPI entrypoint + lifespan
├── models/                     # Trained ML models (read-only)
│   ├── model.weights.h5
│   ├── pipeline.joblib
│   ├── metadata.json
│   └── config.json
├── pyproject.toml
├── uv.lock
├── Dockerfile
├── .dockerignore
└── README.md
```

## Setup

### Prerequisites

- Python 3.14
- [uv](https://github.com/astral-sh/uv) (package manager)
- Docker + Docker Compose (optional, for containerized run)

### Local Development

```bash
cd server

# Create virtual environment & install dependencies
uv sync

# Activate virtual environment
source .venv/bin/activate

# Ensure infra/.env exists with required variables
# (copy from infra/.env.example and adjust)

# Run server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Server will be available at `http://localhost:8000`.  
API docs at `http://localhost:8000/docs`.

### Docker Compose (full stack)

```bash
cd infra

# Create .env from example
cp .env.example .env
# Edit .env with real values (API keys, passwords)

# Start all services
docker compose up --build -d
```

Services:

| Service | Port |
|---|---|
| Nginx | 80 |
| Server (FastAPI) | 8000 (internal) |
| PostgreSQL | 5432 |
| Redis | 6379 |

### Environment Variables

All configuration via `infra/.env`. Key variables:

| Variable | Default | Description |
|---|---|---|
| `FLAZ_BASE_URL` | `https://ai.flaz.id/v1` | LLM API base URL |
| `FLAZ_API_KEY` | — | LLM API key |
| `LLM_MODEL` | `MiniMax-M2.7-highspeed` | LLM model name |
| `DATABASE_URL` | — | PostgreSQL async connection string |
| `REDIS_URL` | — | Redis connection string |
| `MODEL_DIR` | `/app/models` | Path to ML model files |
| `ENVIRONMENT` | `production` | Runtime environment |

### ML Model Loading

Models are loaded **exactly once** during FastAPI startup via `lifespan`.

- `model.weights.h5` — TensorFlow Keras weights
- `pipeline.joblib` — scikit-learn preprocessing pipeline
- `metadata.json` — Model metadata
- `config.json` — Model configuration

If loading fails, the application crashes immediately (fail-fast).  
Models are **never retrained** or modified inside this repository.

## API Endpoints

### `GET /health`

Health check endpoint.

**Success (200):**
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

**Failure (503):**
```json
{
  "status": "unhealthy",
  "error": "Model not loaded"
}
```

### `POST /api/v1/chat`

Send a message to the AI agent.

**Request:**
```json
{
  "message": "Jelaskan konsep neural network",
  "conversation_id": null
}
```

**Response:**
```json
{
  "message": "Neural network adalah...",
  "conversation_id": null
}
```

## LangGraph Agent Flow

```
entry point (input)
    │
    ▼
supervisor ──Send──► predictive_node (ML inference)
    │                      │
    └──Send──► rag_node (vector search)
                                  │
                                  ▼
                          response_node (LLM)
                                  │
                                  ▼
                                END
```

Both `predictive_node` and `rag_node` run **in parallel** via LangGraph `Send`.  
The supervisor does not block — both branches fan out simultaneously.

## Design Decisions

- **Singleton Predictor**: ML model loaded once at startup, reused for all requests. Thread-safe via locking.
- **Fail-fast startup**: If model loading fails, the app crashes immediately rather than serving degraded responses.
- **Independent layers**: ML layer has no knowledge of LangGraph. RAG layer has no knowledge of LangGraph. LangGraph only orchestrates.
- **Environment-driven config**: Zero hardcoded values. pydantic-settings reads from `infra/.env`.
- **OpenAI-compatible LLM**: Any provider with OpenAI-compatible API works via `base_url` configuration.

## Docker

The `Dockerfile` uses multi-stage builds with `uv` for fast dependency installation.

- Model directory `/app/models` is mounted as **read-only volume**
- Runs as non-root `appuser`
- Includes Docker `HEALTHCHECK` against `/health`
- Memory limit: 2G in docker-compose

## Security

- API keys and passwords are never exposed to clients
- Stack traces are never returned in API responses
- All exceptions are logged server-side with `HTTPException` for user-facing errors
- ML model directory is read-only

## Development

### Adding new API routes

1. Create router in `app/api/<name>.py`
2. Register in `app/main.py` via `app.include_router()`

### Adding new agent nodes

1. Create node function in `app/agent/<name>_node.py`
2. Add node to `app/agent/graph.py`
3. Wire edges in `create_graph()`

### Code style

- Type hints everywhere
- Pydantic v2 for all schemas
- Async I/O (except ML inference which is CPU-bound)
- SOLID principles + Clean Architecture
- No `global` keyword
