server/
├── app/
│   ├── main.py                  # entrypoint FastAPI
│   ├── core/                    # config, security, lifespan, exceptions
│   │   ├── config.py
│   │   ├── security.py          # jwt, argon2 hashing
│   │   ├── exceptions.py
│   │   └── logging.py
│   │
│   ├── db/
│   │   ├── session.py           # engine, sessionmaker (sqlalchemy/sqlmodel)
│   │   └── base.py              # base model / metadata
│   │
│   ├── modules/                 # <- ini "domain" nya, per bounded context
│   │   ├── auth/
│   │   │   ├── router.py        # FastAPI routes
│   │   │   ├── schemas.py       # pydantic request/response
│   │   │   ├── models.py        # sqlmodel/sqlalchemy models
│   │   │   ├── service.py       # business logic
│   │   │   └── repository.py    # query/db access
│   │   ├── book/
│   │   │   └── ... (sama polanya)
│   │   └── user/
│   │       └── ...
│   │
│   ├── agents/                  # <- khusus agentic AI (LangChain/LangGraph)
│   │   ├── graphs/              # definisi StateGraph per use-case
│   │   │   └── lixi_chat_graph.py
│   │   ├── nodes/                # node functions yang dipanggil graph
│   │   │   ├── retrieve.py
│   │   │   ├── generate.py
│   │   │   └── tool_call.py
│   │   ├── tools/                # LangChain tools (function calling)
│   │   │   └── book_search_tool.py
│   │   ├── prompts/               # prompt templates (pisahin dari kode!)
│   │   │   └── lixi_system_prompt.py
│   │   ├── state.py               # TypedDict/Pydantic state schema
│   │   └── llm.py                 # inisialisasi ChatOpenAI dll (singleton)
│   │
│   └── shared/                   # util lintas modul
│       ├── deps.py               # FastAPI Depends() umum (get_db, get_current_user)
│       └── utils.py
│
├── tests/
│   ├── modules/
│   └── agents/
├── alembic/                      # migrations kalau pakai
├── .env
├── pyproject.toml
└── uv.lock