import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.api.health import router as health_router
from app.api.chat import router as chat_router
from app.core.config import settings
from app.core.logging import setup_logging
from app.machine_learning.predictor import Predictor

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    setup_logging()
    logger.info("Starting application in %s mode", settings.ENVIRONMENT)
    logger.info("Model directory: %s", settings.MODEL_DIR)

    predictor = Predictor()
    try:
        predictor.load()
        logger.info("Predictor loaded successfully on startup")
    except Exception as e:
        logger.critical("Failed to load predictor on startup: %s", e)
        raise

    yield

    logger.info("Application shutting down")


app = FastAPI(
    title="EduLearn AI Backend",
    version=settings.VERSION,
    lifespan=lifespan,
)

app.include_router(health_router)
app.include_router(chat_router, prefix="/api/v1")
