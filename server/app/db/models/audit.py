import uuid
from datetime import datetime, timezone

from sqlalchemy import BigInteger, DateTime, ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db import Base


class AuditConversation(Base):
    __tablename__ = "audit_conversations"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True
    )
    conversation_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), nullable=False, index=True
    )
    started_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc)
    )
    ended_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    iterations: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    tools_called: Mapped[dict] = mapped_column(JSONB, nullable=False, default=dict)
    citations_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    web_results_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    prediction_label: Mapped[str | None] = mapped_column(String(20), nullable=True)
    error_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    tokens_used: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    firecrawl_cost_estimate_usd: Mapped[float] = mapped_column(
        Numeric(10, 4), nullable=False, default=0.0000
    )

    user: Mapped["User"] = relationship("User", back_populates="audit_conversations")

    def __repr__(self) -> str:
        return f"<AuditConversation id={self.id} conv={self.conversation_id}>"


class AuditUpload(Base):
    __tablename__ = "audit_uploads"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    document_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("knowledge_documents.id"), nullable=False
    )
    uploaded_by: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True
    )
    file_name: Mapped[str] = mapped_column(String(500), nullable=False)
    file_type: Mapped[str] = mapped_column(String(10), nullable=False)
    file_size_bytes: Mapped[int] = mapped_column(BigInteger, nullable=False)
    total_chunks: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="pending")
    error_message: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc)
    )
    processed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    document: Mapped["KnowledgeDocument"] = relationship(
        "KnowledgeDocument", back_populates="audit_uploads"
    )
    uploader: Mapped["User"] = relationship("User", back_populates="audit_uploads")

    def __repr__(self) -> str:
        return f"<AuditUpload id={self.id} file={self.file_name} status={self.status}>"
