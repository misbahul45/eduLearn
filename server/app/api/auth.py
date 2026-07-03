import logging

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.db.models import User
from app.schemas.auth import (
    AuthLoginRequest,
    AuthRefreshRequest,
    AuthRegisterRequest,
    AuthTokenResponse,
    UserResponse,
)
from app.services.auth_service import login, logout, refresh, register

logger = logging.getLogger(__name__)

router = APIRouter(tags=["auth"])


@router.post("/api/v1/auth/register", response_model=AuthTokenResponse, status_code=201)
async def register_endpoint(request: AuthRegisterRequest, db: AsyncSession = Depends(get_db)):
    return await register(request.name, request.email, request.password, db)


@router.post("/api/v1/auth/login", response_model=AuthTokenResponse)
async def login_endpoint(request: AuthLoginRequest, db: AsyncSession = Depends(get_db)):
    return await login(request.email, request.password, db)


@router.post("/api/v1/auth/refresh", response_model=AuthTokenResponse)
async def refresh_endpoint(request: AuthRefreshRequest, db: AsyncSession = Depends(get_db)):
    return await refresh(request.refresh_token, db)


@router.post("/api/v1/auth/logout")
async def logout_endpoint(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await logout(str(current_user.id), db)
    return {"detail": "Berhasil logout"}


@router.get("/api/v1/auth/me", response_model=UserResponse)
async def me_endpoint(current_user: User = Depends(get_current_user)):
    return UserResponse(
        id=str(current_user.id),
        name=current_user.name,
        email=current_user.email,
    )
