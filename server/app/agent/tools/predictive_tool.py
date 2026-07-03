import logging

from langchain_core.tools import tool

from app.machine_learning.predictor import Predictor
from app.schemas.prediction import StudentSignals

logger = logging.getLogger(__name__)


@tool
def predictive_tool(student_signals: StudentSignals | None = None) -> dict:
    """Prediksi kelulusan course (Lulus/Tidak Lulus) berdasarkan data belajar siswa.

    Args:
        student_signals: Data pembelajaran siswa (time_spent, quiz_attempts,
                         education_level, dll.). Field boleh kosong, imputer handle missing.
    """
    logger.info("predictive_tool called")

    predictor = Predictor()
    if not predictor.loaded:
        logger.warning("Predictor not loaded")
        return {"label": "unknown", "probability": 0.0, "class_scores": []}

    try:
        if student_signals is None:
            signals = {}
        else:
            signals = {k: v for k, v in student_signals.model_dump().items() if v is not None}

        result = predictor.predict(signals)
        return {
            "predicted_label": result.predicted_label,
            "confidence": result.confidence,
            "class_scores": [
                {"label": cs.label, "score": cs.score}
                for cs in result.class_scores
            ],
            "model_name": result.model_name,
            "model_version": result.model_version,
            "input_features_used": result.input_features_used,
        }
    except Exception as e:
        logger.exception("Prediction failed")
        return {"label": "error", "probability": 0.0, "class_scores": [], "error": str(e)}
