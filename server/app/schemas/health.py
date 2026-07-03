from pydantic import BaseModel


class HealthResponse(BaseModel):
    status: str
    model_loaded: bool
    model_directory: str
    version: str
    uptime: str
    python: str
    tensorflow: str
    environment: str


class HealthErrorResponse(BaseModel):
    status: str
    error: str
