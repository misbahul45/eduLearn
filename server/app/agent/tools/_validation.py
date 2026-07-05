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


def validate_student_signals(signals: dict[str, Any] | StudentSignals | None) -> StudentSignals:
    if signals is None:
        return StudentSignals()

    if isinstance(signals, StudentSignals):
        return signals

    if not isinstance(signals, dict):
        raise ValueError(f"Expected dict or StudentSignals, got {type(signals)}")

    valid_fields = set(StudentSignals.model_fields.keys())
    filtered = {k: v for k, v in signals.items() if k in valid_fields and v is not None}

    range_checks = {
        "age": (14, 65),
        "digital_literacy_score": (0, 10),
        "app_completion_rate": (0, 100),
        "in_app_quiz_score": (0, 100),
        "skill_pre_score": (0, 100),
        "skill_post_score": (0, 100),
        "essay_vocabulary_richness": (0, 1),
        "essay_coherence_score": (0, 1),
        "video_completion_pct": (0, 100),
        "assignment_submission_rate": (0, 100),
        "content_difficulty_avg": (1, 5),
        "content_recommendations_followed": (0, 100),
        "mastery_score": (0, 100),
        "engagement_consistency": (0, 1),
        "course_duration_weeks": (1, 20),
    }

    non_negative_int = {
        "prior_online_courses", "session_count_weekly", "essay_word_count",
        "essay_grammar_errors", "knowledge_gaps_identified",
        "remediation_modules_completed",
    }
    non_negative_float = {
        "daily_app_minutes", "gamification_engagement", "forum_posts",
        "peer_review_given", "learning_efficiency_score",
        "total_learning_hours", "time_to_mastery_hours",
    }

    for key, value in filtered.items():
        try:
            if key in range_checks:
                lo, hi = range_checks[key]
                v = float(value)
                if not (lo <= v <= hi):
                    raise ValueError(f"{key} harus {lo}–{hi}, mendapat {value}")
                filtered[key] = v
            elif key in non_negative_int:
                filtered[key] = int(value)
                if filtered[key] < 0:
                    raise ValueError(f"{key} tidak boleh negatif")
            elif key in non_negative_float:
                filtered[key] = float(value)
                if filtered[key] < 0:
                    raise ValueError(f"{key} tidak boleh negatif")
            elif key == "education_level":
                allowed = {"High School", "Some College", "Bachelor's", "Graduate", "Doctoral"}
                if value not in allowed:
                    raise ValueError(f"education_level harus salah satu dari {allowed}")
            elif key == "learning_path_type":
                allowed = {"Linear", "Branched", "Adaptive"}
                if value not in allowed:
                    raise ValueError(f"learning_path_type harus salah satu dari {allowed}")
            elif key == "gender":
                allowed = {"Male", "Female", "Non-binary"}
                if value not in allowed:
                    raise ValueError(f"gender harus salah satu dari {allowed}")
            elif key == "employment_status":
                allowed = {
                    "Student", "Employed Full-time", "Employed Part-time",
                    "Self-employed", "Unemployed", "Retired", "Homemaker",
                }
                if value not in allowed:
                    raise ValueError(f"employment_status harus salah satu dari {allowed}")
            elif key == "app_category":
                allowed = {
                    "Test Prep", "Language Learning", "Mathematics", "Soft Skills",
                    "Science", "Programming", "Art & Design", "Business",
                    "Productivity", "Health & Fitness",
                }
                if value not in allowed:
                    raise ValueError(f"app_category harus salah satu dari {allowed}")
            elif key == "essay_topic_category":
                allowed = {"Argumentative", "Descriptive", "Expository", "Narrative", "Persuasive"}
                if value not in allowed:
                    raise ValueError(f"essay_topic_category harus salah satu dari {allowed}")
            elif key == "mooc_platform":
                allowed = {"Coursera", "FutureLearn", "Skillshare", "edX", "Udacity", "Canvas"}
                if value not in allowed:
                    raise ValueError(f"mooc_platform harus salah satu dari {allowed}")
            elif key == "course_category":
                allowed = {
                    "Personal Development", "Technology", "Business & Finance",
                    "Health & Medicine", "Arts & Humanities", "Data Science",
                    "Engineering", "Social Sciences",
                }
                if value not in allowed:
                    raise ValueError(f"course_category harus salah satu dari {allowed}")
        except (ValueError, TypeError) as e:
            raise ValueError(f"Field {key} invalid: {e}")

    return StudentSignals(**filtered)


def sanitize_output_summary(summary: str) -> str:
    return _DANGEROUS_PATTERN_RE.sub("", summary)[:500]