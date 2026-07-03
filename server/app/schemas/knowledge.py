from pydantic import BaseModel


class KnowledgeUploadResponse(BaseModel):
    id: str
    filename: str
    chunks: int
    status: str


class KnowledgeListResponse(BaseModel):
    documents: list[dict]
    total: int
