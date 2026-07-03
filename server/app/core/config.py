from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    MODEL_DIR: str = "/app/models"
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/postgres"
    REDIS_URL: str = "redis://:password@localhost:6379/0"

    FLAZ_BASE_URL: str = "https://ai.flaz.id/v1"
    FLAZ_API_KEY: str = ""
    LLM_MODEL: str = "MiniMax-M2.7-highspeed"

    ENVIRONMENT: str = "production"
    VERSION: str = "1.0.0"

    model_config = {
        "env_file": "../infra/.env",
        "env_file_encoding": "utf-8",
        "case_sensitive": True,
        "extra": "ignore",
    }


settings = Settings()
