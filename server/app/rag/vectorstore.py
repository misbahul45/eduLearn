import logging

from app.core.config import settings

logger = logging.getLogger(__name__)

# DDL untuk pgvector — dijalankan langsung via asyncpg, bukan SQLAlchemy
# (pgvector membutuhkan DDL khusus yang tidak bisa dihasilkan oleh SQLAlchemy ORM)

CREATE_HNSW_INDEX = """
CREATE INDEX IF NOT EXISTS idx_knowledge_chunks_embedding
    ON knowledge_chunks USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);
"""

CREATE_BTREE_INDEXES = """
CREATE INDEX IF NOT EXISTS idx_knowledge_chunks_doc_id ON knowledge_chunks(document_id);
CREATE INDEX IF NOT EXISTS idx_knowledge_chunks_created ON knowledge_chunks(created_at);
CREATE INDEX IF NOT EXISTS idx_knowledge_docs_status ON knowledge_documents(status);
CREATE INDEX IF NOT EXISTS idx_knowledge_chunks_doc_chunk ON knowledge_chunks(document_id, chunk_index);
CREATE INDEX IF NOT EXISTS idx_audit_conversations_user_id ON audit_conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_conversations_ended_at ON audit_conversations(ended_at);
CREATE INDEX IF NOT EXISTS idx_audit_uploads_uploaded_by ON audit_uploads(uploaded_by);
CREATE INDEX IF NOT EXISTS idx_audit_uploads_status ON audit_uploads(status);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_conversations_user_id ON conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_prediction_histories_user_id ON prediction_histories(user_id);
"""


class VectorStore:
    def __init__(self) -> None:
        self._initialized = False

    async def initialize(self) -> None:
        if self._initialized:
            return
        logger.info("Initializing vector store indexes (pgvector)")

        try:
            import asyncpg
        except ImportError:
            logger.warning("asyncpg not installed. Indexes disabled.")
            return

        dsn = settings.DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")
        try:
            conn = await asyncpg.connect(dsn=dsn, timeout=5)
            await conn.execute('CREATE EXTENSION IF NOT EXISTS vector;')
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
            logger.info("Vector store indexes initialized successfully")
        except Exception as e:
            logger.warning("Failed to initialize vector store indexes: %s. RAG will be unavailable.", e)

        self._initialized = True

    @property
    def initialized(self) -> bool:
        return self._initialized
