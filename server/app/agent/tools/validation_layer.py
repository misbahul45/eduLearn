import logging
from typing import Any

from app.agent.tools.rule_engine import check_consistency

logger = logging.getLogger(__name__)

FIELD_RANGES = {
    "age": (14, 65),
    "digital_literacy_score": (0, 10),
    "daily_app_minutes": (0, 180),
    "session_count_weekly": (0, 25),
    "app_completion_rate": (0, 100),
    "in_app_quiz_score": (0, 100),
    "gamification_engagement": (0, 100),
    "skill_pre_score": (0, 100),
    "skill_post_score": (0, 100),
    "essay_word_count": (0, 2000),
    "essay_grammar_errors": (0, 35),
    "essay_vocabulary_richness": (0, 1),
    "essay_coherence_score": (0, 1),
    "course_duration_weeks": (1, 20),
    "video_completion_pct": (0, 100),
    "assignment_submission_rate": (0, 100),
    "forum_posts": (0, 25),
    "peer_review_given": (0, 17),
    "content_difficulty_avg": (1, 5),
    "content_recommendations_followed": (0, 100),
    "knowledge_gaps_identified": (0, 15),
    "remediation_modules_completed": (0, 8),
    "time_to_mastery_hours": (10, 90),
    "mastery_score": (0, 100),
    "learning_efficiency_score": (0, 100),
    "total_learning_hours": (0, 900),
    "engagement_consistency": (0, 1),
}


def validate_synthesized_profile(
    explicit: dict[str, Any],
    inferred: dict[str, Any],
) -> dict[str, Any]:
    logger.info("=" * 80)
    logger.info("VALIDATION LAYER: Checking synthesized profile")

    merged = {**explicit, **inferred}
    issues = []

    for field, value in merged.items():
        if value is None:
            continue
        if field in FIELD_RANGES:
            lo, hi = FIELD_RANGES[field]
            if not (lo <= float(value) <= hi):
                issues.append(f"{field}={value} out of range [{lo}, {hi}]")
                merged[field] = _clamp_to_range(value, lo, hi)
                logger.warning("  Clamped %s from %s to %s", field, value, merged[field])

    consistency_violations = check_consistency(merged)
    issues.extend(consistency_violations)

    n_explicit = sum(1 for v in explicit.values() if v is not None)
    n_inferred = sum(1 for v in inferred.values() if v is not None)
    n_total = n_explicit + n_inferred

    profile_confidence = _compute_profile_confidence(n_explicit, n_inferred, len(issues))

    logger.info("  Explicit fields: %d", n_explicit)
    logger.info("  Inferred fields: %d", n_inferred)
    logger.info("  Total fields: %d", n_total)
    logger.info("  Issues found: %d", len(issues))
    logger.info("  Profile confidence: %.2f", profile_confidence)

    if issues:
        logger.info("  Issues:")
        for issue in issues:
            logger.info("    - %s", issue)

    return {
        "merged": merged,
        "n_explicit": n_explicit,
        "n_inferred": n_inferred,
        "issues": issues,
        "profile_confidence": round(profile_confidence, 3),
    }


def _clamp_to_range(value: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, float(value)))


def _compute_profile_confidence(n_explicit: int, n_inferred: int, n_issues: int) -> float:
    if n_explicit + n_inferred == 0:
        return 0.0

    explicit_weight = 1.0
    inferred_weight = 0.6

    total_score = (n_explicit * explicit_weight + n_inferred * inferred_weight)
    max_score = (n_explicit + n_inferred) * explicit_weight

    base_confidence = total_score / max_score if max_score > 0 else 0.0

    issue_penalty = min(0.3, n_issues * 0.05)

    explicit_bonus = min(0.15, n_explicit * 0.02)

    confidence = base_confidence - issue_penalty + explicit_bonus
    return max(0.0, min(1.0, confidence))