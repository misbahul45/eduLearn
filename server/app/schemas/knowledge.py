from pydantic import BaseModel


class KnowledgeUploadResponse(BaseModel):
    id: str
    filename: str
    chunks: int
    status: str


class KnowledgeListResponse(BaseModel):
    documents: list[dict]
    total: int


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
