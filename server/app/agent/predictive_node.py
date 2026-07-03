import logging

import numpy as np

from app.agent.graph import AgentState
from app.machine_learning.predictor import Predictor

logger = logging.getLogger(__name__)


async def predictive_node(state: AgentState) -> dict:
    logger.info("Predictive node processing: %s", state["input"][:50])

    predictor = Predictor()
    if not predictor.loaded:
        logger.warning("Predictor not loaded, skipping prediction")
        return {"prediction": None}

    try:
        features = np.array([[0.0]])
        result = predictor.predict(features)
        return {"prediction": result.tolist()}
    except Exception as e:
        logger.exception("Prediction failed")
        return {"prediction": None}
