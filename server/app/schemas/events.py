import re
from datetime import datetime, timezone
from typing import Any

from pydantic import BaseModel, Field


def _utcnow() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


class WSEvent(BaseModel):
    type: str
    timestamp: str = ""


class WSMessage(WSEvent):
    type: str = "user_message"
    message: str
    conversation_id: str | None = None


class WSStateUpdate(WSEvent):
    type: str = "state_update"
    node: str
    status: str
    iteration: int = 0


class WSToolCall(WSEvent):
    type: str = "tool_call"
    tool_name: str
    input: dict = Field(default_factory=dict)
    call_id: str = ""


class WSToolResult(WSEvent):
    type: str = "tool_result"
    tool_name: str
    call_id: str = ""
    output_summary: str = ""
    duration_ms: int = 0


class WSToken(WSEvent):
    type: str = "token"
    content: str
    index: int = 0


class WSPredictionResult(WSEvent):
    type: str = "prediction_result"
    node: str = "predictive_node"
    data: dict = Field(default_factory=dict)


class WSCitation(WSEvent):
    type: str = "citation"
    source_id: str = ""
    snippet: str = ""
    score: float = 0.0
    metadata: dict = Field(default_factory=dict)


class WSWebSearch(WSEvent):
    type: str = "web_search_result"
    result_id: str = ""
    url: str = ""
    title: str = ""
    snippet: str = ""
    markdown_excerpt: str = ""
    source: str = "firecrawl"
    relevance_score: float = 0.0


class WSFinal(WSEvent):
    type: str = "final"
    message: str = ""
    conversation_id: str = ""
    citations: list = Field(default_factory=list)
    web_results: list = Field(default_factory=list)
    prediction_present: bool = False
    prediction_label: str = ""


class WSError(WSEvent):
    type: str = "error"
    node: str = ""
    message: str = ""
    fatal: bool = False


class WSPing(WSEvent):
    type: str = "ping"


class WSPong(WSEvent):
    type: str = "pong"


FORBIDDEN_SUBSTRINGS = [
    "sk-",
    "Bearer ",
    "/app/",
    "/usr/",
    "/home/",
    "Traceback",
    "system_prompt",
    "api_key",
    "apiKey",
]

PATH_PATTERN = re.compile(r"/(?:app|usr|home|etc|var|root)/[^\s'\"]+")
KEY_PATTERN = re.compile(r"(sk-[a-zA-Z0-9]{20,}|Bearer\s+\S+)", re.IGNORECASE)


class EventSanitizer:
    @staticmethod
    def sanitize(event: dict[str, Any]) -> dict[str, Any]:
        clean = {k: v for k, v in event.items() if not k.startswith("internal_")}
        clean = EventSanitizer._sanitize_value(clean)
        text = str(clean)
        for forbidden in FORBIDDEN_SUBSTRINGS:
            if forbidden in text:
                clean = EventSanitizer._redact_offender(clean, forbidden)
        return clean

    @staticmethod
    def _sanitize_value(val: Any) -> Any:
        if isinstance(val, dict):
            return {k: EventSanitizer._sanitize_value(v) for k, v in val.items()}
        if isinstance(val, list):
            return [EventSanitizer._sanitize_value(v) for v in val]
        if isinstance(val, str):
            val = KEY_PATTERN.sub("***", val)
            val = PATH_PATTERN.sub("[server path]", val)
            return val
        return val

    @staticmethod
    def _redact_offender(val: Any, forbidden: str) -> Any:
        if isinstance(val, dict):
            return {
                k: ("***REDACTED***" if isinstance(v, str) and forbidden in v
                    else EventSanitizer._redact_offender(v, forbidden))
                for k, v in val.items()
            }
        if isinstance(val, list):
            return [EventSanitizer._redact_offender(v, forbidden) for v in val]
        return val


EVENT_TYPES = {
    "user_message": WSMessage,
    "state_update": WSStateUpdate,
    "tool_call": WSToolCall,
    "tool_result": WSToolResult,
    "token": WSToken,
    "prediction_result": WSPredictionResult,
    "citation": WSCitation,
    "web_search_result": WSWebSearch,
    "final": WSFinal,
    "error": WSError,
    "ping": WSPing,
    "pong": WSPong,
}
