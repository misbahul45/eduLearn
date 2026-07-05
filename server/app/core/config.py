import os
from pathlib import Path
from pydantic import Field
from pydantic_settings import BaseSettings
from dotenv import load_dotenv

env_path = Path(__file__).parent.parent / "infra" / ".env"
load_dotenv(env_path)

class Settings(BaseSettings):
    MODEL_DIR: str = os.getenv("MODEL_DIR", "/app/models")
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL",
        f"postgresql+asyncpg://{os.getenv('POSTGRES_USER', 'ml_prak_user')}:{os.getenv('POSTGRES_PASSWORD', 'change_me_super_secret')}@db:{os.getenv('POSTGRES_PORT', '5432')}/{os.getenv('POSTGRES_DB', 'ml_prak_db')}"
    )
    REDIS_URL: str = os.getenv(
        "REDIS_URL",
        f"redis://:{os.getenv('REDIS_PASSWORD', 'change_me_redis_secret')}@redis:{os.getenv('REDIS_PORT', '6379')}/0"
    )

    FLAZ_BASE_URL: str = os.getenv("FLAZ_BASE_URL", "https://ai.flaz.id/v1")
    FLAZ_API_KEY: str = os.getenv("FLAZ_API_KEY", "")
    LLM_MODEL: str = os.getenv("LLM_MODEL", "MiniMax-M2.7-highspeed")

    JWT_SECRET: str = os.getenv("JWT_SECRET", "change-me")
    JWT_ALGORITHM: str = os.getenv("JWT_ALGORITHM", "HS256")
    JWT_ACCESS_EXPIRE_MIN: int = int(os.getenv("JWT_ACCESS_EXPIRE_MIN", "60"))
    JWT_REFRESH_EXPIRE_DAYS: int = int(os.getenv("JWT_REFRESH_EXPIRE_DAYS", "30"))
    JWT_EXPIRY_HOURS: int = Field(default=24, deprecated=True)

    WS_HEARTBEAT_INTERVAL: int = int(os.getenv("WS_HEARTBEAT_INTERVAL", "20"))
    WS_HEARTBEAT_TIMEOUT: int = int(os.getenv("WS_HEARTBEAT_TIMEOUT", "30"))
    WS_MAX_ITERATIONS: int = int(os.getenv("WS_MAX_ITERATIONS", "5"))
    WS_AUTH_REQUIRED: bool = os.getenv("WS_AUTH_REQUIRED", "true").lower() == "true"
    WS_DEBUG_RAW_EVENTS: bool = os.getenv("WS_DEBUG_RAW_EVENTS", "false").lower() == "true"
    WS_CONNECTION_LIMIT_PER_USER: int = int(os.getenv("WS_CONNECTION_LIMIT_PER_USER", "3"))
    WS_RATE_MSG_PER_MIN: int = int(os.getenv("WS_RATE_MSG_PER_MIN", "30"))
    WS_RATE_TOOL_PER_CONV: int = int(os.getenv("WS_RATE_TOOL_PER_CONV", "20"))
    WS_RATE_TOKENS_PER_CONV: int = int(os.getenv("WS_RATE_TOKENS_PER_CONV", "8000"))
    WS_MAX_CONNECTIONS_PER_USER: int = Field(default=5, deprecated=True)

    FIRECRAWL_API_KEY: str = os.getenv("FIRECRAWL_API_KEY", "")
    FIRECRAWL_CACHE_TTL: int = int(os.getenv("FIRECRAWL_CACHE_TTL", "3600"))
    FIRECRAWL_RATE_PER_CONV: int = int(os.getenv("FIRECRAWL_RATE_PER_CONV", "5"))

    RAG_EMBEDDING_MODEL: str = os.getenv("RAG_EMBEDDING_MODEL", "text-embedding-3-small")
    RAG_CHUNK_SIZE: int = int(os.getenv("RAG_CHUNK_SIZE", "1000"))
    RAG_CHUNK_OVERLAP: int = int(os.getenv("RAG_CHUNK_OVERLAP", "200"))
    RAG_TOP_K: int = int(os.getenv("RAG_TOP_K", "5"))
    RAG_EMBEDDING_DIMENSION: int = int(os.getenv("RAG_EMBEDDING_DIMENSION", "1536"))

    EMBEDDING_MODEL: str = os.getenv("EMBEDDING_MODEL", "text-embedding-3-small")
    EMBEDDING_DIM: int = int(os.getenv("EMBEDDING_DIM", "1536"))

    UPLOAD_MAX_FILE_SIZE_MB: int = int(os.getenv("UPLOAD_MAX_FILE_SIZE_MB", "20"))
    UPLOAD_ALLOWED_TYPES: str = os.getenv("UPLOAD_ALLOWED_TYPES", "pdf,docx,txt,md")
    UPLOAD_DIR: str = os.getenv("UPLOAD_DIR", "/app/uploads")
    UPLOAD_RATE_PER_DAY: int = int(os.getenv("UPLOAD_RATE_PER_DAY", "10"))
    UPLOAD_MAX_SIZE_MB: int = Field(default=10, deprecated=True)
    UPLOAD_ALLOWED_EXTENSIONS: str = Field(default=".pdf,.docx,.txt,.md", deprecated=True)
    UPLOAD_DESTINATION: str = Field(default="/app/uploads", deprecated=True)

    RATE_LIMIT_WINDOW_SECONDS: int = int(os.getenv("RATE_LIMIT_WINDOW_SECONDS", "60"))
    RATE_LIMIT_MAX_REQUESTS: int = int(os.getenv("RATE_LIMIT_MAX_REQUESTS", "30"))

    CORS_ORIGINS: str = os.getenv("CORS_ORIGINS", "http://localhost:80,http://localhost:3000")

    REDIS_CONVERSATION_TTL: int = int(os.getenv("REDIS_CONVERSATION_TTL", "86400"))
    REDIS_CONVERSATION_TTL_SECONDS: int = Field(default=3600, deprecated=True)

    PREDICTION_THRESHOLD: float = float(os.getenv("PREDICTION_THRESHOLD", "0.5"))

    METRICS_ENABLED: bool = os.getenv("METRICS_ENABLED", "false").lower() == "true"
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "production")
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")
    VERSION: str = os.getenv("VERSION", "1.0.0")

    model_config = {
        "env_file": str(env_path),
        "env_file_encoding": "utf-8",
        "case_sensitive": True,
        "extra": "ignore",
    }

settings = Settings()