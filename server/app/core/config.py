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
    JWT_EXPIRY_HOURS: int = 24

    FIRECRAWL_API_KEY: str = ""

    WS_HEARTBEAT_INTERVAL: int = 30
    WS_HEARTBEAT_TIMEOUT: int = 10
    WS_MAX_CONNECTIONS_PER_USER: int = 5

    RAG_EMBEDDING_MODEL: str = "text-embedding-3-small"
    RAG_CHUNK_SIZE: int = 1000
    RAG_CHUNK_OVERLAP: int = 200
    RAG_TOP_K: int = 5
    RAG_EMBEDDING_DIMENSION: int = 1536

    UPLOAD_MAX_SIZE_MB: int = 10
    UPLOAD_ALLOWED_EXTENSIONS: str = ".pdf,.docx,.txt,.md"
    UPLOAD_DESTINATION: str = "/app/uploads"

    RATE_LIMIT_WINDOW_SECONDS: int = 60
    RATE_LIMIT_MAX_REQUESTS: int = 30

    CORS_ORIGINS: str = "http://localhost:80,http://localhost:3000"

    REDIS_CONVERSATION_TTL_SECONDS: int = 3600

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
