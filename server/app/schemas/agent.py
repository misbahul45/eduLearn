from pydantic import BaseModel, Field

from app.schemas.knowledge import Citation, WebSearchResult
from app.schemas.prediction import PredictionResult


class ToolCallRecord(BaseModel):
    tool_name: str
    input_snapshot: str = ""
    output_summary: str = ""
    duration_ms: int = 0
    success: bool = True


__all__ = ["Citation", "PredictionResult", "WebSearchResult", "ToolCallRecord"]
