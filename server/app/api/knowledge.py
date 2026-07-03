import logging

from fastapi import APIRouter, Depends, HTTPException, UploadFile

from app.schemas.knowledge import KnowledgeUploadResponse

logger = logging.getLogger(__name__)

router = APIRouter(tags=["knowledge"])


@router.post("/api/v1/knowledge/upload", response_model=KnowledgeUploadResponse)
async def upload_knowledge(file: UploadFile):
    raise HTTPException(status_code=501, detail="Not implemented")
