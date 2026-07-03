from pydantic import BaseModel, Field


class Citation(BaseModel):
    document: str = ""
    snippet: str = ""
    relevance: float = 0.0


class WebSearchResult(BaseModel):
    url: str = ""
    title: str = ""
    snippet: str = ""


class PredictionResult(BaseModel):
    label: str = ""
    probability: float = 0.0
    class_scores: dict[str, float] = Field(default_factory=dict)


class ToolCallRecord(BaseModel):
    tool_name: str
    input_snapshot: str = ""
    output_summary: str = ""
    duration_ms: int = 0
    success: bool = True
