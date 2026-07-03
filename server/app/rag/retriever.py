import logging

from app.core.config import settings
from app.rag.vectorstore import VectorStore
from app.schemas.knowledge import Citation, CitationMeta

logger = logging.getLogger(__name__)


class Retriever:
    def __init__(self) -> None:
        self._initialized = False
        self._vectorstore = VectorStore()

    async def initialize(self) -> None:
        if self._initialized:
            return
        await self._vectorstore.initialize()
        self._initialized = True

    async def search(self, query: str, top_k: int = 5) -> list[Citation]:
        logger.info("Retriever search: %s | top_k=%d", query[:50], top_k)

        if not query.strip():
            return []

        try:
            embedding = await self._embed(query)
        except Exception as e:
            logger.warning("Embedding failed: %s. Returning empty results.", e)
            return []

        try:
            import asyncpg
        except ImportError:
            logger.warning("asyncpg not installed. Cannot query vector store.")
            return []

        dsn = settings.DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")
        try:
            conn = await asyncpg.connect(dsn=dsn, timeout=5)
            rows = await conn.fetch(
                """
                SELECT
                    kc.id,
                    kc.content,
                    kc.metadata,
                    1 - (kc.embedding <=> $1::vector) AS score
                FROM knowledge_chunks kc
                JOIN knowledge_documents kd ON kd.id = kc.document_id
                WHERE kd.status = 'ready'
                ORDER BY kc.embedding <=> $1::vector
                LIMIT $2
                """,
                embedding,
                top_k,
            )
            await conn.close()
        except Exception as e:
            logger.warning("Vector search failed: %s", e)
            return []

        min_score = 0.5
        results: list[Citation] = []
        for row in rows:
            score = float(row["score"])
            if score < min_score:
                continue
            meta = row["metadata"] or {}
            results.append(Citation(
                source_id=str(row["id"]),
                snippet=str(row["content"])[:300],
                score=score,
                metadata=CitationMeta(
                    title=meta.get("title"),
                    author=meta.get("author"),
                    page=meta.get("page"),
                    url=meta.get("url"),
                    document_id=meta.get("document_id"),
                    file_name=meta.get("file_name"),
                ),
            ))

        return results

    async def _embed(self, text: str) -> list[float]:
        from openai import AsyncOpenAI

        client = AsyncOpenAI(
            api_key=settings.FLAZ_API_KEY,
            base_url=settings.FLAZ_BASE_URL,
        )
        response = await client.embeddings.create(
            model=settings.RAG_EMBEDDING_MODEL,
            input=text,
        )
        return response.data[0].embedding
