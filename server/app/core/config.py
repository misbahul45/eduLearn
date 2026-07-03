from pydantic import Field
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    MODEL_DIR: str = "/app/models"
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/postgres"
    REDIS_URL: str = "redis://:password@localhost:6379/0"

    FLAZ_BASE_URL: str = "https://ai.flaz.id/v1"
    FLAZ_API_KEY: str = ""
    LLM_MODEL: str = "MiniMax-M2.7-highspeed"

    JWT_SECRET: str = "change-me"
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_EXPIRE_MIN: int = 60
    JWT_REFRESH_EXPIRE_DAYS: int = 30
    JWT_EXPIRY_HOURS: int = Field(default=24, deprecated=True)

    WS_HEARTBEAT_INTERVAL: int = 20
    WS_HEARTBEAT_TIMEOUT: int = 30
    WS_MAX_ITERATIONS: int = 5
    WS_AUTH_REQUIRED: bool = True
    WS_DEBUG_RAW_EVENTS: bool = False
    WS_CONNECTION_LIMIT_PER_USER: int = 3
    WS_RATE_MSG_PER_MIN: int = 30
    WS_RATE_TOOL_PER_CONV: int = 20
    WS_RATE_TOKENS_PER_CONV: int = 8000
    WS_MAX_CONNECTIONS_PER_USER: int = Field(default=5, deprecated=True)

    FIRECRAWL_API_KEY: str = ""
    FIRECRAWL_CACHE_TTL: int = 3600
    FIRECRAWL_RATE_PER_CONV: int = 5

    RAG_EMBEDDING_MODEL: str = "text-embedding-3-small"
    RAG_CHUNK_SIZE: int = 1000
    RAG_CHUNK_OVERLAP: int = 200
    RAG_TOP_K: int = 5
    RAG_EMBEDDING_DIMENSION: int = 1536

    EMBEDDING_MODEL: str = "text-embedding-3-small"
    EMBEDDING_DIM: int = 1536

    UPLOAD_MAX_FILE_SIZE_MB: int = 20
    UPLOAD_ALLOWED_TYPES: str = "pdf,docx,txt,md"
    UPLOAD_DIR: str = "/app/uploads"
    UPLOAD_RATE_PER_DAY: int = 10
    UPLOAD_MAX_SIZE_MB: int = Field(default=10, deprecated=True)
    UPLOAD_ALLOWED_EXTENSIONS: str = Field(default=".pdf,.docx,.txt,.md", deprecated=True)
    UPLOAD_DESTINATION: str = Field(default="/app/uploads", deprecated=True)

    RATE_LIMIT_WINDOW_SECONDS: int = 60
    RATE_LIMIT_MAX_REQUESTS: int = 30

    CORS_ORIGINS: str = "http://localhost:80,http://localhost:3000"

    REDIS_CONVERSATION_TTL: int = 86400
    REDIS_CONVERSATION_TTL_SECONDS: int = Field(default=3600, deprecated=True)

    PREDICTION_THRESHOLD: float = 0.5

    METRICS_ENABLED: bool = False
    ENVIRONMENT: str = "production"
    LOG_LEVEL: str = "INFO"
    VERSION: str = "1.0.0"

    model_config = {
        "env_file": "../infra/.env",
        "env_file_encoding": "utf-8",
        "case_sensitive": True,
        "extra": "ignore",
    }


settings = Settings()
