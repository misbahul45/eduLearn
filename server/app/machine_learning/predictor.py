import json
import logging
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import joblib
import numpy as np
import pandas as pd

try:
    import tensorflow as tf
    import keras
except ImportError:
    tf = None
    keras = None

from app.core.config import settings
from app.machine_learning.singleton import SingletonMeta
from app.schemas.prediction import ClassScore, PredictionResult, StudentSignals

logger = logging.getLogger(__name__)

DEFAULT_INPUT_FEATURES = [
    "age", "gender", "education_level", "country", "employment_status",
    "prior_online_courses", "digital_literacy_score", "app_category",
    "daily_app_minutes", "session_count_weekly", "app_completion_rate",
    "in_app_quiz_score", "gamification_engagement", "skill_pre_score",
    "skill_post_score", "essay_topic_category", "essay_word_count",
    "essay_grammar_errors", "essay_vocabulary_richness", "essay_coherence_score",
    "mooc_platform", "course_category", "course_duration_weeks",
    "video_completion_pct", "assignment_submission_rate", "forum_posts",
    "peer_review_given", "learning_path_type", "content_difficulty_avg",
    "content_recommendations_followed", "knowledge_gaps_identified",
    "remediation_modules_completed", "time_to_mastery_hours", "mastery_score",
    "learning_efficiency_score", "total_learning_hours", "engagement_consistency",
]


class Predictor(metaclass=SingletonMeta):
    def __init__(self) -> None:
        self._model: Any = None
        self._bundle: dict[str, Any] = {}
        self._metadata: dict[str, Any] = {}
        self._config: dict[str, Any] = {}
        self._preprocessor: Any = None
        self._pca: Any = None
        self._lda: Any = None
        self._best_dr: str = ""
        self._input_features: list[str] = []
        self._loaded: bool = False
        self._error: str | None = None

    def load(self) -> None:
        if tf is None or keras is None:
            msg = "TensorFlow/Keras is not installed. Cannot load model."
            logger.critical(msg)
            raise RuntimeError(msg)

        model_dir = Path(settings.MODEL_DIR)

        if not model_dir.exists():
            msg = f"Model directory not found: {model_dir}"
            logger.critical(msg)
            raise FileNotFoundError(msg)

        weights_path = model_dir / "model.weights.h5"
        pipeline_path = model_dir / "pipeline.joblib"
        config_path = model_dir / "config.json"
        metadata_path = model_dir / "metadata.json"

        if not weights_path.exists():
            msg = f"Model weights not found: {weights_path}"
            logger.critical(msg)
            raise FileNotFoundError(msg)
        if not pipeline_path.exists():
            msg = f"Pipeline bundle not found: {pipeline_path}"
            logger.critical(msg)
            raise FileNotFoundError(msg)
        if not config_path.exists():
            msg = f"Model config not found: {config_path}"
            logger.critical(msg)
            raise FileNotFoundError(msg)

        logger.info("Loading pipeline bundle from %s", pipeline_path)
        self._bundle = joblib.load(pipeline_path)
        logger.info("Pipeline bundle loaded successfully")

        self._preprocessor = self._bundle.get("preprocessor")
        self._pca = self._bundle.get("pca")
        self._lda = self._bundle.get("lda")
        self._best_dr = self._bundle.get("best_dr", "PCA+LDA")

        raw_features = self._bundle.get("input_features", [])
        if not raw_features:
            logger.warning(
                "Bundle has no 'input_features' key, falling back to default 37 features"
            )
            self._input_features = DEFAULT_INPUT_FEATURES
        else:
            self._input_features = list(raw_features)

        logger.info("Reconstructing model architecture from %s", config_path)
        with open(config_path) as f:
            config_data = json.load(f)

        inner_config = (
            config_data.get("config", config_data)
            if isinstance(config_data, dict)
            else config_data
        )
        self._model = keras.models.Sequential.from_config(inner_config)

        logger.info("Loading model weights from %s", weights_path)
        self._model.load_weights(str(weights_path))
        logger.info("Model weights loaded successfully")

        if metadata_path.exists():
            with open(metadata_path) as f:
                self._metadata = json.load(f)
            logger.info("Metadata loaded from %s", metadata_path)

        self._loaded = True
        logger.info(
            "Predictor fully initialized (best_dr=%s, features=%d)",
            self._best_dr,
            len(self._input_features),
        )

    def _signals_to_dataframe(self, signals: StudentSignals) -> pd.DataFrame:
        data = {}
        for field_name in self._input_features:
            value = getattr(signals, field_name, None)
            data[field_name] = [value if value is not None else np.nan]
        return pd.DataFrame(data)

    def _interpret_confidence(self, confidence: float) -> str:
        if confidence >= 0.90:
            return "Sangat tinggi — model sangat yakin"
        if confidence >= 0.75:
            return "Tinggi — model cukup yakin"
        if confidence >= 0.60:
            return "Sedang — prediksi moderately yakin"
        return "Rendah — prediksi kurang pasti, perlu data lebih lengkap"

    def _generate_recommendations(
        self, predicted_label: str, confidence: float, signals: StudentSignals
    ) -> list[str]:
        recs = []
        is_not_pass = predicted_label.lower() in ["tidak lulus", "not completed"]

        if is_not_pass:
            if signals.video_completion_pct is not None and signals.video_completion_pct < 40:
                recs.append("Tingkatkan penyelesaian video minimal 60%")
            if (
                signals.assignment_submission_rate is not None
                and signals.assignment_submission_rate < 40
            ):
                recs.append("Kumpulkan tugas lebih rutin — target submission rate minimal 50%")
            if signals.session_count_weekly is not None and signals.session_count_weekly < 4:
                recs.append("Perbanyak sesi belajar — minimal 4-5 sesi per minggu")
            if signals.daily_app_minutes is not None and signals.daily_app_minutes < 30:
                recs.append("Tingkatkan waktu belajar harian minimal 40-60 menit")
            if (
                signals.engagement_consistency is not None
                and signals.engagement_consistency < 0.4
            ):
                recs.append(
                    "Jaga konsistensi belajar — belajar rutin lebih baik daripada maraton"
                )
            if not recs:
                recs.append("Fokus pada konsistensi belajar dan engagement aktif di platform")
        else:
            if confidence >= 0.85:
                recs.append("Performa sangat baik! Pertahankan konsistensi belajar")
            else:
                recs.append("Tren positif — tingkatkan quiz score dan forum participation")

        return recs[:3]

    def _identify_risk_factors(self, signals: StudentSignals) -> list[str]:
        risks = []
        if (
            signals.engagement_consistency is not None
            and signals.engagement_consistency < 0.3
        ):
            risks.append("Konsistensi engagement sangat rendah")
        if signals.video_completion_pct is not None and signals.video_completion_pct < 25:
            risks.append("Penyelesaian video sangat rendah")
        if (
            signals.assignment_submission_rate is not None
            and signals.assignment_submission_rate < 20
        ):
            risks.append("Submission rate tugas sangat rendah")
        if signals.total_learning_hours is not None and signals.total_learning_hours < 20:
            risks.append("Total jam belajar sangat sedikit")
        if signals.in_app_quiz_score is not None and signals.in_app_quiz_score < 50:
            risks.append("Skor quiz dalam app di bawah rata-rata")
        if (
            signals.skill_post_score is not None
            and signals.skill_pre_score is not None
            and signals.skill_post_score - signals.skill_pre_score < 10
        ):
            risks.append("Peningkatan skill sangat minimal")
        return risks[:3]

    def predict(self, signals: StudentSignals) -> PredictionResult:
        if not self._loaded or self._model is None:
            raise RuntimeError("Predictor not loaded. Call load() first.")

        df = self._signals_to_dataframe(signals)
        X_pre = self._preprocessor.transform(df)

        if self._best_dr == "PCA+LDA" and self._pca is not None and self._lda is not None:
            X_pca = self._pca.transform(X_pre)
            X_lda = self._lda.transform(X_pre)
            X_dr = np.hstack([X_pca, X_lda])
        elif self._best_dr == "PCA" and self._pca is not None:
            X_dr = self._pca.transform(X_pre)
        elif self._best_dr == "LDA" and self._lda is not None:
            X_dr = self._lda.transform(X_pre)
        else:
            X_dr = X_pre

        prob_lulus = float(self._model.predict(X_dr, verbose=0).ravel()[0])
        prob_tidak = 1.0 - prob_lulus
        predicted_class = 1 if prob_lulus >= 0.5 else 0
        confidence = prob_lulus if predicted_class == 1 else prob_tidak
        predicted_label = "Lulus" if predicted_class == 1 else "Tidak Lulus"

        recommendations = self._generate_recommendations(predicted_label, confidence, signals)
        risk_factors = self._identify_risk_factors(signals)
        features_used = [
            f for f in self._input_features if getattr(signals, f, None) is not None
        ]

        return PredictionResult(
            predicted_label=predicted_label,
            confidence=round(confidence, 4),
            confidence_interpretation=self._interpret_confidence(confidence),
            class_scores=[
                ClassScore(label="Tidak Lulus", score=round(prob_tidak, 4)),
                ClassScore(label="Lulus", score=round(prob_lulus, 4)),
            ],
            model_name=self._bundle.get("best_model_name", "Deep MLP (TensorFlow)"),
            model_version=self._metadata.get("model_version", "1.0.0"),
            input_features_used=features_used,
            recommendations=recommendations,
            risk_factors=risk_factors,
            generated_at=datetime.now(timezone.utc),
        )

    def health(self) -> dict[str, Any]:
        return {
            "loaded": self._loaded,
            "error": self._error,
            "best_dr": self._best_dr,
            "n_features": len(self._input_features),
            "model_name": self._bundle.get("best_model_name", "Deep MLP (TensorFlow)"),
        }

    @property
    def loaded(self) -> bool:
        return self._loaded

    @property
    def error(self) -> str | None:
        return self._error