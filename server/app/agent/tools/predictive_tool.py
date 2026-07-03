import logging

import numpy as np

from app.machine_learning.predictor import Predictor

logger = logging.getLogger(__name__)


async def predictive_predict(features: list[float] | None = None) -> dict:
    logger.info("predictive_tool called")

    predictor = Predictor()
    if not predictor.loaded:
        logger.warning("Predictor not loaded")
        return {"label": "unknown", "probability": 0.0, "class_scores": {}}

    try:
        if features is None:
            features = [0.0]
        input_array = np.array([features])
        result = predictor.predict(input_array)
        prob = float(result[0][0]) if result.ndim > 1 else float(result[0])
        label = "Lulus" if prob >= 0.5 else "Tidak Lulus"

        return {
            "label": label,
            "probability": round(prob, 4),
            "class_scores": {"Tidak Lulus": round(1 - prob, 4), "Lulus": round(prob, 4)},
        }
    except Exception as e:
        logger.exception("Prediction failed")
        return {"label": "error", "probability": 0.0, "class_scores": {}, "error": str(e)}
