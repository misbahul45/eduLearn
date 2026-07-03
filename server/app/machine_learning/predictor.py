import json
import logging
from pathlib import Path
from typing import Any

import joblib
import numpy as np

try:
    import tensorflow as tf
except ImportError:
    tf = None

from app.core.config import settings
from app.machine_learning.singleton import SingletonMeta

logger = logging.getLogger(__name__)


class Predictor(metaclass=SingletonMeta):
    def __init__(self) -> None:
        self._model: tf.keras.Model | None = None
        self._pipeline: Any | None = None
        self._metadata: dict[str, Any] = {}
        self._config: dict[str, Any] = {}
        self._loaded: bool = False
        self._error: str | None = None

    def load(self) -> None:
        if tf is None:
            msg = "TensorFlow is not installed. Cannot load model."
            logger.critical(msg)
            raise RuntimeError(msg)

        model_dir = Path(settings.MODEL_DIR)

        if not model_dir.exists():
            msg = f"Model directory not found: {model_dir}"
            logger.critical(msg)
            raise FileNotFoundError(msg)

        model_path = model_dir / "model.weights.h5"
        pipeline_path = model_dir / "pipeline.joblib"
        metadata_path = model_dir / "metadata.json"
        config_path = model_dir / "config.json"

        if not model_path.exists():
            msg = f"Model weights not found: {model_path}"
            logger.critical(msg)
            raise FileNotFoundError(msg)
        if not pipeline_path.exists():
            msg = f"Pipeline not found: {pipeline_path}"
            logger.critical(msg)
            raise FileNotFoundError(msg)

        logger.info("Loading model weights from %s", model_path)
        self._model = tf.keras.models.load_model(str(model_path))
        logger.info("Model loaded successfully")

        logger.info("Loading pipeline from %s", pipeline_path)
        self._pipeline = joblib.load(pipeline_path)
        logger.info("Pipeline loaded successfully")

        if metadata_path.exists():
            with open(metadata_path) as f:
                self._metadata = json.load(f)
            logger.info("Metadata loaded from %s", metadata_path)

        if config_path.exists():
            with open(config_path) as f:
                self._config = json.load(f)
            logger.info("Config loaded from %s", config_path)

        self._loaded = True
        logger.info("Predictor fully initialized")

    def predict(self, features: np.ndarray) -> np.ndarray:
        if not self._loaded or self._model is None:
            raise RuntimeError("Predictor not loaded. Call load() first.")
        transformed = self._pipeline.transform(features) if self._pipeline else features
        return self._model.predict(transformed, verbose=0)

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
