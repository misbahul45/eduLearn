from collections.abc import Callable
from typing import Optional

from pydantic import BaseModel, Field

from app.schemas.agent import Citation, PredictionResult, ToolCallRecord, WebSearchResult


class AgentState(BaseModel):
    conversation_id: str = ""
    user_id: str = ""
    user_message: str = ""
    scratchpad: list[dict] = Field(default_factory=list)
    tool_calls: list[ToolCallRecord] = Field(default_factory=list)
    iteration: int = 0
    max_iterations: int = 5
    model_config = {"arbitrary_types_allowed": True}
    citations: list[Citation] = Field(default_factory=list)
    web_search_results: list[WebSearchResult] = Field(default_factory=list)
    prediction: PredictionResult | None = None
    final_answer: str | None = None
    error: str | None = None
    state_update_callback: Optional[Callable] = None

    def add_tool_call(self, tool_name: str, inp: dict, output_summary: str = "", success: bool = True) -> None:
        self.tool_calls.append(ToolCallRecord(
            tool_name=tool_name,
            input_snapshot=str(inp)[:200],
            output_summary=output_summary[:200],
            success=success,
        ))
