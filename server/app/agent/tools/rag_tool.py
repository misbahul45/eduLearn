import logging

from app.core.config import settings
from app.machine_learning.predictor import Predictor

logger = logging.getLogger(__name__)


async def rag_search(query: str, top_k: int = 5) -> list[dict]:
    logger.info("rag_tool search: %s", query[:50])
    return []


async def rag_ingest(file_path: str, filename: str) -> dict:
    logger.info("rag_tool ingest: %s", filename)
    return {"filename": filename, "chunks": 0, "status": "pending"}
