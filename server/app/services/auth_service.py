import uuid
from datetime import datetime, timedelta, timezone

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.db import get_db
from app.db.models import RefreshToken, User

pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")
security = HTTPBearer(auto_error=False)

ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE = timedelta(minutes=settings.JWT_ACCESS_EXPIRE_MIN)
REFRESH_TOKEN_EXPIRE = timedelta(days=settings.JWT_REFRESH_EXPIRE_DAYS)


def _hash_password(password: str) -> str:
    return pwd_context.hash(password)


def _verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


def _create_access_token(user_id: str) -> str:
    now = datetime.now(timezone.utc)
    payload = {
        "sub": user_id,
        "type": "access",
        "iat": now,
        "exp": now + ACCESS_TOKEN_EXPIRE,
    }
    return jwt.encode(payload, settings.JWT_SECRET, algorithm=ALGORITHM)


def _create_refresh_token(user_id: str) -> str:
    now = datetime.now(timezone.utc)
    payload = {
        "sub": user_id,
        "type": "refresh",
        "jti": str(uuid.uuid4()),
        "iat": now,
        "exp": now + REFRESH_TOKEN_EXPIRE,
    }
    return jwt.encode(payload, settings.JWT_SECRET, algorithm=ALGORITHM)


def _decode_token(token: str) -> dict:
    try:
        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=[ALGORITHM])
        return payload
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token tidak valid atau sudah kedaluwarsa",
        )


async def register(
    name: str,
    email: str,
    password: str,
    db: AsyncSession,
) -> dict:
    result = await db.execute(select(User).where(User.email == email))
    if result.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email sudah terdaftar",
        )

    user = User(
        id=uuid.uuid4(),
        name=name,
        email=email,
        password_hash=_hash_password(password),
    )
    db.add(user)
    await db.flush()

    access_token = _create_access_token(str(user.id))
    refresh_token = _create_refresh_token(str(user.id))
    payload = _decode_token(refresh_token)

    db.add(
        RefreshToken(
            user_id=user.id,
            token_hash=pwd_context.hash(refresh_token),
            expires_at=datetime.fromtimestamp(payload["exp"], tz=timezone.utc),
        )
    )

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
    }


async def login(
    email: str,
    password: str,
    db: AsyncSession,
) -> dict:
    result = await db.execute(select(User).where(User.email == email))
    user = result.scalar_one_or_none()

    if not user or not _verify_password(password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email atau password salah",
        )

    access_token = _create_access_token(str(user.id))
    refresh_token = _create_refresh_token(str(user.id))
    payload = _decode_token(refresh_token)

    db.add(
        RefreshToken(
            user_id=user.id,
            token_hash=pwd_context.hash(refresh_token),
            expires_at=datetime.fromtimestamp(payload["exp"], tz=timezone.utc),
        )
    )

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
    }


async def refresh(
    refresh_token: str,
    db: AsyncSession,
) -> dict:
    payload = _decode_token(refresh_token)
    if payload.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token tidak valid",
        )

    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token tidak valid",
        )

    result = await db.execute(
        select(RefreshToken).where(RefreshToken.token_hash.isnot(None))
    )
    stored_tokens = result.scalars().all()

    valid_token = None
    for st in stored_tokens:
        if not st.revoked and pwd_context.verify(refresh_token, st.token_hash):
            valid_token = st
            break

    if not valid_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token tidak valid atau sudah dicabut",
        )

    valid_token.revoked = True
    new_access = _create_access_token(user_id)
    new_refresh = _create_refresh_token(user_id)
    new_payload = _decode_token(new_refresh)

    db.add(
        RefreshToken(
            user_id=uuid.UUID(user_id),
            token_hash=pwd_context.hash(new_refresh),
            expires_at=datetime.fromtimestamp(new_payload["exp"], tz=timezone.utc),
        )
    )

    return {
        "access_token": new_access,
        "refresh_token": new_refresh,
        "token_type": "bearer",
    }


async def logout(
    user_id: str,
    db: AsyncSession,
) -> None:
    result = await db.execute(
        select(RefreshToken).where(
            RefreshToken.user_id == uuid.UUID(user_id),
            RefreshToken.revoked == False,
        )
    )
    for token in result.scalars().all():
        token.revoked = True


async def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(security),
    db: AsyncSession = Depends(get_db),
) -> User:
    if not credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token tidak valid atau sudah kedaluwarsa",
        )

    payload = _decode_token(credentials.credentials)
    if payload.get("type") != "access":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token tidak valid",
        )

    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token tidak valid",
        )

    result = await db.execute(
        select(User).where(User.id == uuid.UUID(user_id))
    )
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token tidak valid atau sudah kedaluwarsa",
        )

    return user
