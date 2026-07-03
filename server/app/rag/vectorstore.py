import logging

from app.core.config import settings

logger = logging.getLogger(__name__)


CREATE_KNOWLEDGE_DOCUMENTS = """
CREATE TABLE IF NOT EXISTS knowledge_documents (
    id UUID PRIMARY KEY,
    file_name TEXT NOT NULL,
    file_type TEXT NOT NULL CHECK (file_type IN ('pdf', 'docx', 'txt', 'md')),
    file_size_bytes BIGINT NOT NULL,
    title TEXT NOT NULL,
    author TEXT,
    description TEXT,
    tags TEXT[] NOT NULL DEFAULT '{}',
    total_chunks INT NOT NULL DEFAULT 0,
    uploaded_by UUID NOT NULL,
    status TEXT NOT NULL DEFAULT 'processing' CHECK (status IN ('processing', 'ready', 'failed')),
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    processed_at TIMESTAMPTZ
);
"""

ALTER_DOCUMENTS_ADD_COLUMNS = """
ALTER TABLE knowledge_documents
    ADD COLUMN IF NOT EXISTS title TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS author TEXT,
    ADD COLUMN IF NOT EXISTS description TEXT,
    ADD COLUMN IF NOT EXISTS tags TEXT[] NOT NULL DEFAULT '{}';
"""

CREATE_KNOWLEDGE_CHUNKS = """
CREATE TABLE IF NOT EXISTS knowledge_chunks (
    id UUID PRIMARY KEY,
    document_id UUID NOT NULL REFERENCES knowledge_documents(id) ON DELETE CASCADE,
    chunk_index INT NOT NULL,
    content TEXT NOT NULL,
    embedding vector(1536),
    metadata JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
"""

CREATE_HNSW_INDEX = """
CREATE INDEX IF NOT EXISTS idx_knowledge_chunks_embedding
    ON knowledge_chunks USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);
"""

CREATE_BTREE_INDEXES = """
CREATE INDEX IF NOT EXISTS idx_knowledge_chunks_doc_id ON knowledge_chunks(document_id);
CREATE INDEX IF NOT EXISTS idx_knowledge_chunks_created ON knowledge_chunks(created_at);
CREATE INDEX IF NOT EXISTS idx_knowledge_docs_status ON knowledge_documents(status);
"""


class VectorStore:
    def __init__(self) -> None:
        self._initialized = False

    async def initialize(self) -> None:
        if self._initialized:
            return
        logger.info("Initializing vector store (pgvector)")

        try:
            import asyncpg
        except ImportError:
            logger.warning("asyncpg not installed. Vector store disabled.")
            return

        dsn = settings.DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")
        try:
            conn = await asyncpg.connect(dsn=dsn, timeout=5)
            await conn.execute('CREATE EXTENSION IF NOT EXISTS vector;')
            await conn.execute(CREATE_KNOWLEDGE_DOCUMENTS)
            await conn.execute(ALTER_DOCUMENTS_ADD_COLUMNS)
            await conn.execute(CREATE_KNOWLEDGE_CHUNKS)
            try:
                await conn.execute(CREATE_HNSW_INDEX)
            except Exception:
                logger.info("HNSW index may already exist or not supported, continuing")
            for stmt in CREATE_BTREE_INDEXES.split(";"):
                s = stmt.strip()
                if s:
                    try:
                        await conn.execute(s)
                    except Exception:
                        pass
            await conn.close()
            logger.info("Vector store initialized successfully")
        except Exception as e:
            logger.warning("Failed to initialize vector store: %s. RAG will be unavailable.", e)

        self._initialized = True

    @property
    def initialized(self) -> bool:
        return self._initialized
