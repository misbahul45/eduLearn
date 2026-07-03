import logging

from app.core.config import settings

logger = logging.getLogger(__name__)


async def firecrawl_search(query: str, limit: int = 5) -> list[dict]:
    logger.info("firecrawl_tool search: %s", query[:50])

    if not settings.FIRECRAWL_API_KEY or settings.FIRECRAWL_API_KEY == "fcc_xxx":
        logger.warning("FIRECRAWL_API_KEY not configured")
        return []

    return []
