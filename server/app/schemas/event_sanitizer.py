"""
Enhanced Event Sanitizer — permissive, preserve semua new fields.

Perubahan dari versi lama:
1. Whitelist semua field yang dibutuhkan oleh Flutter UI:
   - parallel_group, iteration, success, reasoning_preview, tool_calls_count
   - info_sufficient, plan_completed, missing_aspects, next_action, quality_score
   - needs_planning, steps (untuk plan_generated)
2. Sanitize sensitive data (input args mungkin berisi PII)
3. Truncate long strings untuk performance
4. Ensure JSON serializable (datetime → ISO string)
"""
import logging
from datetime import datetime, date
from typing import Any

logger = logging.getLogger(__name__)


# Field yang di-allow per event type
ALLOWED_FIELDS = {
    # System
    "connection": {"type", "status", "timestamp"},
    "ping": {"type", "timestamp"},
    "pong": {"type", "timestamp"},

    # State update
    "state_update": {
        "type", "node", "status", "iteration",
        "reasoning_preview", "tool_calls_count",
        "reflection_count", "timestamp",
    },

    # Plan
    "plan_generated": {
        "type", "node", "steps", "reasoning", "needs_planning", "timestamp",
    },

    # Tool execution
    "tool_call": {
        "type", "tool_name", "input", "call_id",
        "parallel_group", "iteration", "timestamp",
    },
    "tool_result": {
        "type", "tool_name", "call_id", "output_summary",
        "duration_ms", "success", "parallel_group", "iteration", "timestamp",
    },

    # Results
    "citation": {
        "type", "source_id", "snippet", "score", "metadata", "timestamp",
    },
    "web_search_result": {
        "type", "result_id", "url", "title", "snippet",
        "markdown_excerpt", "source", "relevance_score", "timestamp",
    },
    "prediction_result": {
        "type", "node", "data", "timestamp",
    },

    # Reflection
    "reflection": {
        "type", "node",
        "info_sufficient", "plan_completed", "missing_aspects",
        "next_action", "reason", "quality_score",
        "timestamp",
    },

    # Streaming
    "token": {"type", "content", "index", "timestamp"},

    # Final
    "final": {
        "type", "message", "conversation_id",
        "citations", "web_results",
        "prediction_present", "prediction_label", "timestamp",
    },

    # Error
    "error": {"type", "node", "message", "fatal", "timestamp"},
}

# Field yang harus di-sanitize (mask PII)
SENSITIVE_INPUT_FIELDS = {
    "user_narrative", "token", "password", "api_key", "secret",
}

# Max length untuk string fields
MAX_STRING_LENGTH = 5000
MAX_SNIPPET_LENGTH = 500
MAX_INPUT_PREVIEW = 500


class EventSanitizer:
    """Sanitize events sebelum dikirim ke client."""

    @staticmethod
    def sanitize(event: dict) -> dict:
        """Sanitize event: filter fields, mask PII, ensure serializable."""
        if not isinstance(event, dict):
            return {"type": "error", "message": "Invalid event format"}

        event_type = event.get("type", "unknown")

        # Unknown type → log warning, return as-is (jangan block)
        if event_type not in ALLOWED_FIELDS:
            logger.warning("Unknown event type: %s", event_type)
            return EventSanitizer._ensure_serializable(event)

        allowed = ALLOWED_FIELDS[event_type]
        sanitized: dict[str, Any] = {}

        for field in allowed:
            if field not in event:
                continue

            value = event[field]

            # Sanitize berdasarkan field name
            if field == "input":
                value = EventSanitizer._sanitize_input(value)
            elif field == "reasoning_preview":
                value = EventSanitizer._truncate(value, 300)
            elif field == "message" and event_type == "final":
                value = EventSanitizer._truncate(value, MAX_STRING_LENGTH)
            elif field == "markdown_excerpt":
                value = EventSanitizer._truncate(value, MAX_STRING_LENGTH)
            elif field == "snippet":
                value = EventSanitizer._truncate(value, MAX_SNIPPET_LENGTH)
            elif field == "output_summary":
                value = EventSanitizer._truncate(value, 200)
            elif isinstance(value, str):
                value = EventSanitizer._truncate(value, MAX_STRING_LENGTH)

            # Ensure JSON serializable
            value = EventSanitizer._ensure_serializable(value)

            sanitized[field] = value

        return sanitized

    @staticmethod
    def _sanitize_input(input_val: Any) -> dict:
        """Mask sensitive fields dalam tool input args."""
        if not isinstance(input_val, dict):
            return {"_value": str(input_val)[:MAX_INPUT_PREVIEW]}

        sanitized_input = {}
        for key, val in input_val.items():
            if key in SENSITIVE_INPUT_FIELDS:
                # Mask sensitive field
                if isinstance(val, str) and len(val) > 10:
                    sanitized_input[key] = val[:3] + "***" + val[-3:]
                else:
                    sanitized_input[key] = "***"
            elif isinstance(val, str):
                sanitized_input[key] = EventSanitizer._truncate(val, MAX_INPUT_PREVIEW)
            elif isinstance(val, (dict, list)):
                sanitized_input[key] = EventSanitizer._ensure_serializable(val)
            else:
                sanitized_input[key] = val

        return sanitized_input

    @staticmethod
    def _truncate(value: Any, max_len: int) -> str:
        """Truncate string to max_len."""
        if not isinstance(value, str):
            return value
        if len(value) <= max_len:
            return value
        return value[:max_len] + "...[truncated]"

    @staticmethod
    def _ensure_serializable(value: Any) -> Any:
        """Convert non-JSON-serializable types."""
        if isinstance(value, datetime):
            return value.isoformat().replace("+00:00", "Z")
        if isinstance(value, date):
            return value.isoformat()
        if isinstance(value, dict):
            return {k: EventSanitizer._ensure_serializable(v) for k, v in value.items()}
        if isinstance(value, list):
            return [EventSanitizer._ensure_serializable(v) for v in value]
        if isinstance(value, (set, tuple)):
            return list(value)
        if hasattr(value, "model_dump"):
            # Pydantic model
            return EventSanitizer._ensure_serializable(value.model_dump())
        if hasattr(value, "__dict__"):
            # Custom object → dict
            try:
                return EventSanitizer._ensure_serializable(value.__dict__)
            except Exception:
                return str(value)
        return value
