import logging

from app.core.config import settings

logger = logging.getLogger(__name__)


class Retriever:
    def __init__(self) -> None:
        self._initialized = False

    async def initialize(self) -> None:
        if self._initialized:
            return
        logger.info("Initializing retriever with DATABASE_URL")
        self._initialized = True

    async def search(self, query: str, top_k: int = 5) -> list[str]:
        logger.info("Searching for: %s | top_k=%d", query[:50], top_k)
        return []
