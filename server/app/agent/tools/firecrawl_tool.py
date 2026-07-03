import hashlib
import json
import logging
from datetime import datetime, timezone

import httpx
from langchain_core.tools import tool

from app.agent.tools._validation import validate_firecrawl_query
from app.core.config import settings
from app.schemas.knowledge import WebSearchResult

logger = logging.getLogger(__name__)

FIRECRAWL_TIMEOUT = 15.0
FIRECRAWL_CACHE_TTL = 3600
FIRECRAWL_MAX_RESULTS = 5


@tool
async def firecrawl_tool(query: str, max_results: int = 3) -> list[dict]:
    """Cari informasi terkini di web via Firecrawl API.

    Args:
        query: Kata kunci pencarian (max 200 karakter).
        max_results: Jumlah hasil maksimal (default 3, max 5).
    """
    try:
        query, max_results = validate_firecrawl_query(query, max_results)
    except ValueError as e:
        logger.warning("firecrawl_tool validation failed: %s", e)
        return []

    logger.info("firecrawl_tool search: %s | max_results=%d", query[:50], max_results)

    if not settings.FIRECRAWL_API_KEY or settings.FIRECRAWL_API_KEY == "fcc_xxx":
        raise RuntimeError("FIRECRAWL_API_KEY belum di-set. Tidak bisa mencari info web.")

    cache_key = _cache_key(query)
    cached = await _get_cached(cache_key)
    if cached is not None:
        logger.info("Firecrawl cache hit for query: %s", query[:50])
        return cached

    try:
        async with httpx.AsyncClient(timeout=FIRECRAWL_TIMEOUT) as client:
            resp = await client.post(
                "https://api.firecrawl.dev/v1/search",
                headers={
                    "Authorization": f"Bearer {settings.FIRECRAWL_API_KEY}",
                    "Content-Type": "application/json",
                },
                json={
                    "query": query,
                    "limit": max_results,
                    "scrapeOptions": {
                        "formats": ["markdown"],
                        "onlyMainContent": True,
                        "maxTokens": 1000,
                    },
                },
            )
            resp.raise_for_status()
            data = resp.json()
    except httpx.TimeoutException:
        logger.error("Firecrawl request timed out after %ds", FIRECRAWL_TIMEOUT)
        raise RuntimeError("Pencarian web gagal karena waktu habis. Coba lagi nanti.")
    except httpx.HTTPStatusError as e:
        logger.error("Firecrawl HTTP error: %d %s", e.response.status_code, e.response.text[:200])
        raise RuntimeError("Layanan pencarian web sedang bermasalah. Gunakan referensi lokal.")

    results = []
    for i, item in enumerate(data.get("data", [])):
        results.append({
            "result_id": f"ws_{i:03d}",
            "url": item.get("url", ""),
            "title": item.get("title", "Tanpa judul"),
            "snippet": _sanitize(item.get("description") or "")[:300],
            "markdown_excerpt": _sanitize(item.get("markdown") or "")[:800],
            "source": "firecrawl",
            "relevance_score": 0.0,
        })

    await _set_cached(cache_key, results)
    return results


def _sanitize(text: str) -> str:
    text = text.replace("<script", "&lt;script").replace("</script", "&lt;/script")
    text = text.replace("<style", "&lt;style").replace("</style", "&lt;/style")
    import re
    text = re.sub(r'<[^>]*>', '', text)
    return text


def _cache_key(query: str) -> str:
    raw = f"firecrawl:{query.strip().lower()}"
    return hashlib.md5(raw.encode()).hexdigest()


async def _get_cached(key: str) -> list[dict] | None:
    try:
        import redis.asyncio as aioredis
        r = aioredis.from_url(settings.REDIS_URL, socket_connect_timeout=2)
        val = await r.get(f"ws:cache:{key}")
        await r.aclose()
        if val:
            return json.loads(val)
    except Exception:
        logger.debug("Redis cache unavailable, skipping cache read")
    return None


async def _set_cached(key: str, results: list[dict]) -> None:
    try:
        import redis.asyncio as aioredis
        r = aioredis.from_url(settings.REDIS_URL, socket_connect_timeout=2)
        await r.setex(f"ws:cache:{key}", FIRECRAWL_CACHE_TTL, json.dumps(results))
        await r.aclose()
    except Exception:
        logger.debug("Redis cache unavailable, skipping cache write")
