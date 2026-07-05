import logging
from datetime import datetime, timezone

from langchain_core.tools import tool

from app.agent.tools._validation import validate_student_signals
from app.machine_learning.predictor import Predictor

logger = logging.getLogger(__name__)


@tool
async def predictive_tool(student_signals: dict | None = None) -> dict:
    """Prediksi kelulusan course (Lulus/Tidak Lulus) menggunakan Deep Learning model (Deep MLP TensorFlow).

    Args:
        student_signals: Dictionary data pembelajaran siswa. Field opsional (semua boleh kosong,
            missing values di-handle oleh imputer). Field kunci yang paling berpengaruh:
            - video_completion_pct (float 0-100): Persentase video yang ditonton
            - assignment_submission_rate (float 0-100): Rate pengumpulan tugas
            - session_count_weekly (int): Jumlah sesi belajar per minggu
            - in_app_quiz_score (float 0-100): Skor quiz dalam app
            - total_learning_hours (float): Total jam belajar
            - engagement_consistency (float 0-1): Konsistensi engagement
            - daily_app_minutes (float): Menit penggunaan app per hari
            - skill_pre_score, skill_post_score (float 0-100): Skor skill sebelum/sesudah
            - education_level (str): High School/Some College/Bachelor's/Graduate/Doctoral
            - learning_path_type (str): Linear/Branched/Adaptive
            - Dan 27 field lainnya (age, gender, country, app_category, dll.)
    """
    logger.info("predictive_tool called")

    try:
        signals = validate_student_signals(student_signals)
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