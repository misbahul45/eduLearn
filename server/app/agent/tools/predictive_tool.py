import json
import logging
from datetime import datetime, timezone

from langchain_core.tools import tool

from app.agent.tools._validation import validate_student_signals
from app.agent.tools.profile_synthesizer import synthesize_student_profile
from app.machine_learning.predictor import Predictor

logger = logging.getLogger(__name__)


@tool
async def predictive_tool(
    user_narrative: str = "",
    student_signals: dict | None = None,
) -> dict:
    """Prediksi kelulusan course (Lulus/Tidak Lulus) menggunakan Deep Learning model.

    Args:
        user_narrative: Narasi/cerita user tentang kondisi belajarnya. Digunakan untuk
            sintesis profil yang lebih realistis. Contoh: "Saya mahasiswa semester 5,
            akhir-akhir ini kehilangan motivasi, cuma belajar 2x seminggu..."
        student_signals: Dictionary data eksplisit dari user. Field kunci:
            - video_completion_pct (0-100)
            - assignment_submission_rate (0-100)
            - session_count_weekly (int)
            - in_app_quiz_score (0-100)
            - total_learning_hours (float)
            - daily_app_minutes (float)
            - engagement_consistency (0-1)
            Field lain opsional, missing values akan di-sintesis oleh rule engine.
    """
    logger.info("=" * 80)
    logger.info("PREDICTIVE TOOL CALLED")
    logger.info("User narrative: %s", user_narrative[:300] if user_narrative else "(empty)")
    logger.info("Raw student_signals from AI:")
    try:
        logger.info(
            json.dumps(student_signals or {}, indent=2, ensure_ascii=False, default=str)
        )
    except Exception as e:
        logger.warning("Failed to serialize raw input: %s", e)

    explicit_data = student_signals or {}

    try:
        synthesis = synthesize_student_profile(
            user_narrative=user_narrative,
            explicit_data=explicit_data,
        )
    except Exception as e:
        logger.exception("Profile synthesis failed")
        synthesis = {
            "merged_for_prediction": explicit_data,
            "n_explicit": len([v for v in explicit_data.values() if v is not None]),
            "n_inferred": 0,
            "validation_issues": [f"Synthesis failed: {e}"],
            "profile_confidence": 0.3,
            "explicit_fields": {},
            "inferred_fields": {},
        }

    merged = synthesis["merged_for_prediction"]

    try:
        signals = validate_student_signals(merged)
    except ValueError as e:
        logger.warning("predictive_tool validation failed: %s", e)
        return {
            "predicted_label": "error",
            "confidence": 0.0,
            "confidence_interpretation": "Validasi gagal",
            "class_scores": [],
            "recommendations": [],
            "risk_factors": [],
            "error": str(e),
            "generated_at": datetime.now(timezone.utc).isoformat(),
        }

    logger.info("=" * 80)
    logger.info("Validated StudentSignals (after synthesis)")
    for field in signals.model_dump():
        logger.info("%-40s : %s", field, getattr(signals, field))

    predictor = Predictor()
    if not predictor.loaded:
        logger.warning("Predictor not loaded")
        return {
            "predicted_label": "unknown",
            "confidence": 0.0,
            "confidence_interpretation": "Model belum dimuat",
            "class_scores": [],
            "recommendations": ["Hubungi administrator untuk memuat model prediksi"],
            "risk_factors": [],
            "generated_at": datetime.now(timezone.utc).isoformat(),
        }

    try:
        result = predictor.predict(signals)
        return {
            "predicted_label": result.predicted_label,
            "confidence": result.confidence,
            "confidence_interpretation": result.confidence_interpretation,
            "class_scores": [
                {"label": cs.label, "score": cs.score}
                for cs in result.class_scores
            ],
            "model_name": result.model_name,
            "model_version": result.model_version,
            "input_features_used": result.input_features_used,
            "recommendations": result.recommendations,
            "risk_factors": result.risk_factors,
            "generated_at": result.generated_at.isoformat(),
            "synthesis_metadata": {
                "n_explicit_fields": synthesis["n_explicit"],
                "n_inferred_fields": synthesis["n_inferred"],
                "profile_confidence": synthesis["profile_confidence"],
                "validation_issues": synthesis["validation_issues"],
                "explicit_fields": list(synthesis["explicit_fields"].keys()),
                "inferred_fields": {
                    k: {"value": v["value"], "reason": v["reason"]}
                    for k, v in synthesis["inferred_fields"].items()
                },
            },
        }
    except Exception as e:
        logger.exception("Prediction failed")
        return {
            "predicted_label": "error",
            "confidence": 0.0,
            "confidence_interpretation": "Prediksi gagal",
            "class_scores": [],
            "recommendations": [],
            "risk_factors": [],
            "error": str(e),
            "generated_at": datetime.now(timezone.utc).isoformat(),
        }