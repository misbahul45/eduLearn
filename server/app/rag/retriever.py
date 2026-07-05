import logging

from app.core.config import settings
from app.rag.vectorstore import VectorStore
from app.schemas.knowledge import Citation, CitationMeta

logger = logging.getLogger(__name__)

_QUERY_REWRITE_SYSTEM_PROMPT = (
    "Kamu adalah query rewriter untuk sistem RAG di platform belajar akademis. "
    "Tugasmu mengubah pertanyaan/permintaan pengguna menjadi query pencarian yang "
    "berisi konsep, teori, istilah akademis, atau topik yang MENDASARI permintaan itu — "
    "bukan menyalin kata-kata harfiahnya.\n\n"
    "Contoh:\n"
    "Input: cara naikin quiz score\n"
    "Output: strategi belajar efektif active recall spaced repetition teknik ujian retensi memori\n\n"
    "Input: kenapa saya susah fokus belajar\n"
    "Output: gangguan konsentrasi belajar manajemen perhatian teknik fokus produktivitas kognitif\n\n"
    "Aturan:\n"
    "- Jangan menjawab pertanyaannya.\n"
    "- Jangan menambahkan kalimat pembuka/penutup.\n"
    "- Balas HANYA dengan query hasil rewrite dalam Bahasa Indonesia, satu baris, tanpa tanda kutip."
)


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
        logger.info("Retriever search (original): %s | top_k=%d", query[:80], top_k)

        if not query.strip():
            return []

        search_query = await self._rewrite_query(query)
        if search_query != query:
            logger.info("Retriever search (rewritten): %s", search_query[:120])

        try:
            embedding = await self._embed(search_query)
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
            try:
                await conn.execute("CREATE EXTENSION IF NOT EXISTS vector")
            except Exception as e:
                logger.debug("Vector extension check skipped: %s", e)

            embedding_str = "[" + ",".join(str(x) for x in embedding) + "]"

            rows = await conn.fetch(
                """
                SELECT
                    kc.id,
                    kc.content,
                    kc.extra_metadata AS metadata,
                    kc.document_id,
                    kd.file_name,
                    kd.title AS doc_title,
                    kd.author AS doc_author,
                    1 - (kc.embedding::vector <=> $1::vector) AS score
                FROM knowledge_chunks kc
                JOIN knowledge_documents kd ON kd.id = kc.document_id
                WHERE kd.status = 'ready'
                  AND kc.embedding IS NOT NULL
                ORDER BY kc.embedding::vector <=> $1::vector
                LIMIT $2
                """,
                embedding_str,
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
                    title=meta.get("title") or row.get("doc_title"),
                    author=meta.get("author") or row.get("doc_author"),
                    page=meta.get("page"),
                    url=meta.get("url"),
                    document_id=str(row["document_id"]),
                    file_name=row.get("file_name"),
                ),
            ))

        return results

    async def _rewrite_query(self, query: str) -> str:
        if not getattr(settings, "RAG_QUERY_REWRITE_ENABLED", True):
            return query

        from openai import AsyncOpenAI

        client = AsyncOpenAI(
            api_key=settings.FLAZ_API_KEY,
            base_url=settings.FLAZ_BASE_URL,
        )
        try:
            response = await client.chat.completions.create(
                model=settings.RAG_QUERY_REWRITE_MODEL,
                messages=[
                    {"role": "system", "content": _QUERY_REWRITE_SYSTEM_PROMPT},
                    {"role": "user", "content": query},
                ],
                temperature=0.3,
                max_tokens=80,
            )
            rewritten = (response.choices[0].message.content or "").strip()
            rewritten = rewritten.strip('"').strip("'")
            return rewritten if rewritten else query
        except Exception as e:
            logger.warning("Query rewrite failed: %s. Falling back to original query.", e)
            return query

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