import logging

from fastapi import APIRouter, Depends, HTTPException

from app.schemas.auth import (
    AuthLoginRequest,
    AuthRefreshRequest,
    AuthRegisterRequest,
    AuthTokenResponse,
    UserResponse,
)

logger = logging.getLogger(__name__)

router = APIRouter(tags=["auth"])


@router.post("/api/v1/auth/login", response_model=AuthTokenResponse)
async def login(request: AuthLoginRequest):
    raise HTTPException(status_code=501, detail="Not implemented")


@router.post("/api/v1/auth/register", response_model=AuthTokenResponse)
async def register(request: AuthRegisterRequest):
    raise HTTPException(status_code=501, detail="Not implemented")


@router.post("/api/v1/auth/logout")
async def logout():
    raise HTTPException(status_code=501, detail="Not implemented")


@router.post("/api/v1/auth/refresh", response_model=AuthTokenResponse)
async def refresh(request: AuthRefreshRequest):
    raise HTTPException(status_code=501, detail="Not implemented")


@router.get("/api/v1/auth/me", response_model=UserResponse)
async def me():
    raise HTTPException(status_code=501, detail="Not implemented")
