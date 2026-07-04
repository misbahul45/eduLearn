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
from app.schemas.prediction import ClassScore, PredictionResult

logger = logging.getLogger(__name__)


class Predictor(metaclass=SingletonMeta):
    def __init__(self) -> None:
        self._model: tf.keras.Model | None = None
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

        self._preprocessor = self._bundle["preprocessor"]
        self._pca = self._bundle.get("pca")
        self._lda = self._bundle.get("lda")
        self._best_dr = self._bundle.get("best_dr", "")
        self._input_features = self._bundle.get("input_features", [])

        logger.info("Reconstructing model architecture from %s", config_path)
        with open(config_path) as f:
            config_data = json.load(f)

        # [FIX] Keras 3 get_config() returns full serialization wrapper
        # with 'module', 'class_name', 'config' keys.
        # Sequential.from_config() only needs the inner 'config' dict.
        inner_config = config_data.get("config", config_data) if isinstance(config_data, dict) else config_data
        self._model = keras.models.Sequential.from_config(inner_config)

        logger.info("Loading model weights from %s", weights_path)
        self._model.load_weights(str(weights_path))
        logger.info("Model weights loaded successfully")

        if metadata_path.exists():
            with open(metadata_path) as f:
                self._metadata = json.load(f)
            logger.info("Metadata loaded from %s", metadata_path)

        self._loaded = True
        logger.info("Predictor fully initialized (best_dr=%s, features=%d)", self._best_dr, len(self._input_features))

    def predict(self, student_signals: dict) -> PredictionResult:
        if not self._loaded or self._model is None:
            raise RuntimeError("Predictor not loaded. Call load() first.")

        df = pd.DataFrame([student_signals], columns=self._input_features)

        X_pre = self._preprocessor.transform(df)

        if self._best_dr == "PCA" and self._pca is not None:
            X_dr = self._pca.transform(X_pre)
        elif self._best_dr == "LDA" and self._lda is not None:
            X_dr = self._lda.transform(X_pre)
        elif self._best_dr == "PCA+LDA" and self._pca is not None and self._lda is not None:
            X_pca = self._pca.transform(X_pre)
            X_lda = self._lda.transform(X_pre)
            X_dr = np.hstack([X_pca, X_lda])
        else:
            X_dr = X_pre

        prob_lulus = float(self._model.predict(X_dr, verbose=0).ravel()[0])
        prob_tidak = 1.0 - prob_lulus

        predicted_label = "Lulus" if prob_lulus >= 0.5 else "Tidak Lulus"
        confidence = prob_lulus if predicted_label == "Lulus" else prob_tidak

        model_name = self._bundle.get("best_model_name", "Deep MLP (TensorFlow)")
        model_version = self._metadata.get("model_version", "1.0.0")

        return PredictionResult(
            predicted_label=predicted_label,
            confidence=round(confidence, 4),
            class_scores=[
                ClassScore(label="Tidak Lulus", score=round(prob_tidak, 4)),
                ClassScore(label="Lulus", score=round(prob_lulus, 4)),
            ],
            model_name=model_name,
            model_version=model_version,
            input_features_used=list(self._input_features),
            generated_at=datetime.now(timezone.utc),
        )

    def health(self) -> dict[str, Any]:
        return {
            "loaded": self._loaded,
            "error": self._error,
        }

    @property
    def loaded(self) -> bool:
        return self._loaded

    @property
    def error(self) -> str | None:
        return self._error