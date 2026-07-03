from datetime import datetime

from pydantic import BaseModel, Field


class KnowledgeUploadResponse(BaseModel):
    document_id: str
    file_name: str
    file_type: str
    file_size_bytes: int
    title: str
    status: str
    message: str
    created_at: datetime


class UploadedBy(BaseModel):
    user_id: str
    name: str


class KnowledgeDocument(BaseModel):
    document_id: str
    file_name: str
    file_type: str
    file_size_bytes: int
    title: str
    author: str | None = None
    description: str | None = None
    tags: list[str] = Field(default_factory=list)
    total_chunks: int
    status: str
    error_message: str | None = None
    uploaded_by: UploadedBy
    created_at: datetime
    processed_at: datetime | None = None


class KnowledgeListResponse(BaseModel):
    items: list[KnowledgeDocument]
    total: int
    page: int
    page_size: int


class CitationMeta(BaseModel):
    title: str | None = None
    author: str | None = None
    page: int | None = None
    url: str | None = None
    document_id: str | None = None
    file_name: str | None = None


class Citation(BaseModel):
    source_id: str
    snippet: str
    score: float
    metadata: CitationMeta


class WebSearchResult(BaseModel):
    result_id: str = ""
    url: str = ""
    title: str = ""
    snippet: str = ""
    markdown_excerpt: str = ""
    source: str = "firecrawl"
    relevance_score: float = 0.0
