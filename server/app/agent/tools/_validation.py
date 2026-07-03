import re
from typing import Any

from app.schemas.prediction import StudentSignals

_HTML_TAG_RE = re.compile(r"<[^>]*>")
_CONTROL_CHAR_RE = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f]")
_URL_RE = re.compile(r"https?://[^\s]+", re.IGNORECASE)
_SCRIPT_RE = re.compile(r"<\s*(script|iframe)\b", re.IGNORECASE)
_JAVASCRIPT_RE = re.compile(r"javascript\s*:", re.IGNORECASE)
_DANGEROUS_PATTERN_RE = re.compile(r"[`;&|]+")


def validate_rag_query(query: str) -> str:
    if not query or not query.strip():
        raise ValueError("Query tidak boleh kosong.")
    if len(query) > 500:
        query = query[:500]
    query = _HTML_TAG_RE.sub("", query)
    if _SCRIPT_RE.search(query):
        raise ValueError("Query mengandung tag skrip yang tidak diizinkan.")
    if _JAVASCRIPT_RE.search(query):
        raise ValueError("Query mengandung javascript: yang tidak diizinkan.")
    return query.strip()


def validate_firecrawl_query(query: str, max_results: int) -> tuple[str, int]:
    if not query or not query.strip():
        raise ValueError("Query tidak boleh kosong.")
    if len(query) > 200:
        query = query[:200]
    query = _CONTROL_CHAR_RE.sub("", query)
    query = _HTML_TAG_RE.sub("", query)
    if _URL_RE.search(query):
        raise ValueError("Query tidak boleh mengandung URL.")
    max_results = min(max(max_results, 1), 5)
    return query.strip(), max_results


def validate_student_signals(signals: dict[str, Any] | StudentSignals | None) -> dict[str, Any]:
    if signals is None:
        return {}
    if isinstance(signals, StudentSignals):
        signals = signals.model_dump(exclude_none=True)
    for key in signals:
        if signals[key] is None:
            continue
        if key == "time_spent_minutes":
            if not (0 <= signals[key] <= 10000):
                raise ValueError(f"time_spent_minutes harus 0–10000, mendapat {signals[key]}")
        elif key == "video_completion_rate":
            if not (0.0 <= signals[key] <= 1.0):
                raise ValueError(f"video_completion_rate harus 0.0–1.0, mendapat {signals[key]}")
        elif key in ("quiz_score_avg", "quiz_score_max"):
            if not (0 <= signals[key] <= 100):
                raise ValueError(f"{key} harus 0–100, mendapat {signals[key]}")
        elif key in ("quiz_attempts", "forum_posts", "login_frequency", "assignment_completion_rate_times_100"):
            if signals[key] < 0:
                raise ValueError(f"{key} tidak boleh negatif, mendapat {signals[key]}")
        elif key == "education_level":
            allowed = {"High School", "Some College", "Bachelor's", "Graduate", "Doctoral"}
            if signals[key] not in allowed:
                raise ValueError(f"education_level harus salah satu dari {allowed}, mendapat {signals[key]}")
        elif key == "learning_path_type":
            allowed = {"Linear", "Branched", "Adaptive"}
            if signals[key] not in allowed:
                raise ValueError(f"learning_path_type harus salah satu dari {allowed}, mendapat {signals[key]}")
    return signals


def sanitize_output_summary(summary: str) -> str:
    return _DANGEROUS_PATTERN_RE.sub("", summary)[:500]
