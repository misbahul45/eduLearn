import logging

from langchain_core.tools import tool

from app.core.config import settings

logger = logging.getLogger(__name__)


@tool
async def firecrawl_tool(query: str, limit: int = 5) -> list[dict]:
    """Cari informasi terkini dari web menggunakan Firecrawl.

    Args:
        query: Kata kunci pencarian.
        limit: Jumlah hasil maksimal.
    """
    logger.info("firecrawl_tool search: %s | limit=%d", query[:50], limit)

    if not settings.FIRECRAWL_API_KEY or settings.FIRECRAWL_API_KEY == "fcc_xxx":
        logger.warning("FIRECRAWL_API_KEY not configured")
        return []

    return []
