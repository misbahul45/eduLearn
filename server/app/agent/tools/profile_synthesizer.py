import logging
from typing import Any

from app.agent.tools.rule_engine import apply_rule_engine
from app.agent.tools.validation_layer import validate_synthesized_profile

logger = logging.getLogger(__name__)


def synthesize_student_profile(user_narrative: str, explicit_data: dict[str, Any]) -> dict[str, Any]:
    logger.info("=" * 80)
    logger.info("PROFILE SYNTHESIZER: Building realistic student profile")
    logger.info("User narrative: %s", user_narrative[:200])
    logger.info("Explicit data: %s", explicit_data)

    inferred, reasoning = apply_rule_engine(explicit_data)

    validation_result = validate_synthesized_profile(explicit_data, inferred)

    synthesis_result = {
        "user_narrative": user_narrative,
        "explicit_fields": {
            k: {"value": v, "source": "explicit"}
            for k, v in explicit_data.items()
            if v is not None
        },
        "inferred_fields": {
            k: {
                "value": v,
                "source": "inferred",
                "reason": reasoning.get(k, "Rule-based inference"),
            }
            for k, v in inferred.items()
            if v is not None
        },
        "merged_for_prediction": validation_result["merged"],
        "n_explicit": validation_result["n_explicit"],
        "n_inferred": validation_result["n_inferred"],
        "validation_issues": validation_result["issues"],
        "profile_confidence": validation_result["profile_confidence"],
    }

    logger.info("=" * 80)
    logger.info("SYNTHESIS COMPLETE")
    logger.info("  Profile confidence: %.2f", synthesis_result["profile_confidence"])
    logger.info("  Explicit: %d, Inferred: %d",
                synthesis_result["n_explicit"], synthesis_result["n_inferred"])
    logger.info("=" * 80)

    return synthesis_result