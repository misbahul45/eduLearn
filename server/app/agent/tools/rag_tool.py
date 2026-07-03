import logging

from langchain_core.tools import tool

from app.rag.retriever import Retriever

logger = logging.getLogger(__name__)


@tool
async def rag_tool(query: str, top_k: int = 5) -> list[dict]:
    """Cari referensi akademis dari knowledge base lokal (RAG / pgvector).

    Args:
        query: Kata kunci pencarian dalam Bahasa Indonesia.
        top_k: Jumlah hasil yang diminta (max 10).
    """
    logger.info("rag_tool search: %s | top_k=%d", query[:50], top_k)

    retriever = Retriever()
    try:
        citations = await retriever.search(query, top_k=top_k)
        return [
            {
                "source_id": c.source_id,
                "snippet": c.snippet[:300],
                "score": c.score,
                "metadata": c.metadata.model_dump(exclude_none=True),
            }
            for c in citations
        ]
    except Exception as e:
        logger.exception("RAG search failed")
        return []


async def rag_ingest(file_path: str, filename: str) -> dict:
    logger.info("rag_tool ingest: %s", filename)
    return {"filename": filename, "chunks": 0, "status": "pending"}
