import logging
from typing import Any

logger = logging.getLogger(__name__)

GROUP_A_INFERABLE = {
    "engagement_consistency",
    "forum_posts",
    "peer_review_given",
    "content_recommendations_followed",
    "knowledge_gaps_identified",
    "learning_efficiency_score",
    "mastery_score",
    "skill_post_score",
    "skill_pre_score",
    "gamification_engagement",
    "app_completion_rate",
    "remediation_modules_completed",
    "time_to_mastery_hours",
}

GROUP_B_NO_INFER = {
    "age",
    "gender",
    "country",
    "education_level",
    "employment_status",
    "mooc_platform",
    "app_category",
    "course_category",
    "essay_topic_category",
    "learning_path_type",
}

CORRELATION_RULES = {
    "engagement_consistency": {
        "base": "session_count_weekly / 10",
        "bounds": (0.0, 1.0),
        "correlated_with": ["session_count_weekly", "daily_app_minutes", "total_learning_hours"],
        "logic": "low_sessions_low_consistency",
    },
    "skill_post_score": {
        "base": "in_app_quiz_score",
        "delta": (-10, 10),
        "bounds": (0.0, 100.0),
        "logic": "quiz_proximate",
    },
    "skill_pre_score": {
        "base": "in_app_quiz_score - 15",
        "delta": (-10, 5),
        "bounds": (0.0, 100.0),
        "logic": "pre_lower_than_post",
    },
    "mastery_score": {
        "base": "in_app_quiz_score",
        "delta": (-8, 8),
        "bounds": (0.0, 100.0),
        "logic": "quiz_proximate",
    },
    "learning_efficiency_score": {
        "base": "computed",
        "formula": "f(video, assignment, quiz, hours)",
        "bounds": (0.0, 100.0),
        "logic": "efficiency_composite",
    },
    "forum_posts": {
        "base": "daily_app_minutes / 15",
        "bounds": (0.0, 25.0),
        "logic": "app_usage_proportional",
    },
    "peer_review_given": {
        "base": "forum_posts / 2",
        "bounds": (0.0, 17.0),
        "logic": "forum_proportional",
    },
    "content_recommendations_followed": {
        "base": "video_completion_pct * 0.8",
        "delta": (-15, 10),
        "bounds": (0.0, 100.0),
        "logic": "engagement_proportional",
    },
    "knowledge_gaps_identified": {
        "base": "inverse_quiz",
        "formula": "max(0, (100 - quiz) / 15)",
        "bounds": (0, 15),
        "logic": "low_quiz_more_gaps",
    },
    "remediation_modules_completed": {
        "base": "knowledge_gaps / 2",
        "bounds": (0, 8),
        "logic": "gaps_proportional",
    },
    "time_to_mastery_hours": {
        "base": "total_learning_hours * 0.8",
        "delta": (-5, 10),
        "bounds": (10.0, 90.0),
        "logic": "learning_hours_proportional",
    },
    "gamification_engagement": {
        "base": "session_count_weekly * 8",
        "delta": (-10, 15),
        "bounds": (0.0, 100.0),
        "logic": "sessions_proportional",
    },
    "app_completion_rate": {
        "base": "video_completion_pct * 0.9",
        "delta": (-10, 10),
        "bounds": (0.0, 100.0),
        "logic": "video_proximate",
    },
}

CONSISTENCY_CONSTRAINTS = [
    {
        "name": "assignment_video_consistency",
        "check": lambda d: not (d.get("assignment_submission_rate", 0) > 80 and d.get("video_completion_pct", 100) < 20),
        "message": "High assignment rate contradicts very low video completion",
    },
    {
        "name": "quiz_mastery_consistency",
        "check": lambda d: abs((d.get("in_app_quiz_score", 50) or 50) - (d.get("mastery_score", 50) or 50)) <= 25,
        "message": "Quiz score and mastery score differ by more than 25 points",
    },
    {
        "name": "skill_improvement",
        "check": lambda d: (d.get("skill_post_score", 50) or 50) >= (d.get("skill_pre_score", 50) or 50) - 5,
        "message": "Skill post score significantly lower than pre score",
    },
    {
        "name": "efficiency_hours",
        "check": lambda d: not ((d.get("learning_efficiency_score", 50) or 50) > 70 and (d.get("total_learning_hours", 50) or 50) < 15),
        "message": "High efficiency with very low learning hours is unrealistic",
    },
    {
        "name": "engagement_sessions",
        "check": lambda d: not ((d.get("engagement_consistency", 0.5) or 0.5) > 0.8 and (d.get("session_count_weekly", 5) or 5) < 3),
        "message": "High consistency with very few sessions is unrealistic",
    },
]


def apply_rule_engine(explicit_data: dict[str, Any]) -> dict[str, Any]:
    logger.info("=" * 80)
    logger.info("RULE ENGINE: Applying correlation rules")
    logger.info("Explicit fields: %s", list(explicit_data.keys()))

    inferred: dict[str, Any] = {}
    reasoning: dict[str, str] = {}

    for field, rules in CORRELATION_RULES.items():
        if field in explicit_data and explicit_data[field] is not None:
            continue
        if field not in GROUP_A_INFERABLE:
            continue

        try:
            value, reason = _compute_field(field, rules, explicit_data)
            if value is not None:
                inferred[field] = value
                reasoning[field] = reason
                logger.info("  Inferred %-35s = %s (%s)", field, value, reason)
        except Exception as e:
            logger.warning("  Failed to infer %s: %s", field, e)

    return inferred, reasoning


def _compute_field(field: str, rules: dict, data: dict) -> tuple[Any, str]:
    logic = rules.get("logic", "")
    bounds = rules.get("bounds", (None, None))

    if logic == "low_sessions_low_consistency":
        sessions = data.get("session_count_weekly")
        daily = data.get("daily_app_minutes")
        if sessions is None:
            return None, ""
        base = min(sessions / 10.0, 1.0)
        if daily and daily < 30:
            base *= 0.7
        value = _clamp(base, bounds)
        return round(value, 3), f"session_count_weekly={sessions}, daily={daily}"

    if logic == "quiz_proximate":
        quiz = data.get("in_app_quiz_score")
        if quiz is None:
            return None, ""
        delta = rules.get("delta", (-10, 10))
        base = quiz + (delta[0] + delta[1]) / 2
        if field == "skill_pre_score":
            base = quiz - 15 + (delta[0] + delta[1]) / 2
        value = _clamp(base, bounds)
        return round(value, 2), f"in_app_quiz_score={quiz}, delta={delta}"

    if logic == "efficiency_composite":
        video = data.get("video_completion_pct", 50) or 50
        assignment = data.get("assignment_submission_rate", 50) or 50
        quiz = data.get("in_app_quiz_score", 50) or 50
        hours = data.get("total_learning_hours", 30) or 30
        base = (video * 0.3 + assignment * 0.3 + quiz * 0.3) * min(hours / 40.0, 1.2)
        value = _clamp(base, bounds)
        return round(value, 2), f"composite(video={video}, assign={assignment}, quiz={quiz}, hours={hours})"

    if logic == "app_usage_proportional":
        daily = data.get("daily_app_minutes")
        if daily is None:
            return None, ""
        base = daily / 15.0
        value = _clamp(base, bounds)
        return round(value, 1), f"daily_app_minutes={daily}"

    if logic == "forum_proportional":
        forum = inferred_or_explicit(data, "forum_posts")
        if forum is None:
            return None, ""
        value = _clamp(forum / 2.0, bounds)
        return round(value, 1), f"forum_posts={forum}"

    if logic == "engagement_proportional":
        video = data.get("video_completion_pct")
        if video is None:
            return None, ""
        delta = rules.get("delta", (-15, 10))
        base = video * 0.8 + (delta[0] + delta[1]) / 2
        value = _clamp(base, bounds)
        return round(value, 2), f"video_completion_pct={video}"

    if logic == "low_quiz_more_gaps":
        quiz = data.get("in_app_quiz_score")
        if quiz is None:
            return None, ""
        base = max(0, (100 - quiz) / 15)
        value = int(_clamp(base, bounds))
        return value, f"in_app_quiz_score={quiz}, gaps=(100-{quiz})/15"

    if logic == "gaps_proportional":
        gaps = inferred_or_explicit(data, "knowledge_gaps_identified")
        if gaps is None:
            return None, ""
        value = int(_clamp(gaps / 2.0, bounds))
        return value, f"knowledge_gaps_identified={gaps}"

    if logic == "learning_hours_proportional":
        hours = data.get("total_learning_hours")
        if hours is None:
            return None, ""
        delta = rules.get("delta", (-5, 10))
        base = hours * 0.8 + (delta[0] + delta[1]) / 2
        value = _clamp(base, bounds)
        return round(value, 2), f"total_learning_hours={hours}"

    if logic == "sessions_proportional":
        sessions = data.get("session_count_weekly")
        if sessions is None:
            return None, ""
        delta = rules.get("delta", (-10, 15))
        base = sessions * 8 + (delta[0] + delta[1]) / 2
        value = _clamp(base, bounds)
        return round(value, 2), f"session_count_weekly={sessions}"

    if logic == "video_proximate":
        video = data.get("video_completion_pct")
        if video is None:
            return None, ""
        delta = rules.get("delta", (-10, 10))
        base = video * 0.9 + (delta[0] + delta[1]) / 2
        value = _clamp(base, bounds)
        return round(value, 2), f"video_completion_pct={video}"

    if logic == "pre_lower_than_post":
        quiz = data.get("in_app_quiz_score")
        post = inferred_or_explicit(data, "skill_post_score")
        if quiz is None:
            return None, ""
        base = quiz - 15
        if post is not None:
            base = min(base, post - 5)
        value = _clamp(base, bounds)
        return round(value, 2), f"in_app_quiz_score={quiz}, skill_post={post}"

    return None, ""


def inferred_or_explicit(data: dict, field: str) -> Any:
    if field in data and data[field] is not None:
        return data[field]
    return None


def _clamp(value: float, bounds: tuple) -> float:
    lo, hi = bounds
    if lo is not None:
        value = max(lo, value)
    if hi is not None:
        value = min(hi, value)
    return value


def check_consistency(data: dict[str, Any]) -> list[str]:
    violations = []
    for constraint in CONSISTENCY_CONSTRAINTS:
        try:
            if not constraint["check"](data):
                violations.append(constraint["message"])
                logger.warning("  Consistency violation: %s", constraint["message"])
        except Exception as e:
            logger.debug("  Constraint check failed: %s", e)
    return violations