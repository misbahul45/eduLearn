import logging

from fastapi import APIRouter, Depends, HTTPException

from app.schemas.auth import UserResponse

logger = logging.getLogger(__name__)

router = APIRouter(tags=["users"])


@router.get("/api/v1/users/me", response_model=UserResponse)
async def get_current_user():
    raise HTTPException(status_code=501, detail="Not implemented")


@router.get("/api/v1/users/stats")
async def get_user_stats():
    raise HTTPException(status_code=501, detail="Not implemented")
