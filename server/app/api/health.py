import platform
import time

from fastapi import APIRouter, HTTPException

from app.core.config import settings
from app.machine_learning.predictor import Predictor

try:
    import tensorflow as tf
    TF_VERSION = tf.__version__
except ImportError:
    tf = None
    TF_VERSION = "not installed"

router = APIRouter(tags=["health"])

_start_time: float = time.time()


@router.get("/health")
async def health():
    predictor = Predictor()
    status = predictor.health()

    if not status["loaded"]:
        raise HTTPException(
            status_code=503,
            detail={
                "status": "unhealthy",
                "error": status["error"] or "Model not loaded",
            },
        )

    return {
        "status": "healthy",
        "model_loaded": True,
        "model_directory": settings.MODEL_DIR,
        "version": settings.VERSION,
        "uptime": f"{time.time() - _start_time:.2f}s",
        "python": platform.python_version(),
        "tensorflow": TF_VERSION,
        "environment": settings.ENVIRONMENT,
    }
