from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_db
from app.db.models import User
from app.services.auth_service import get_current_user as _get_current_user

__all__ = ["get_db", "get_current_user"]

get_current_user = _get_current_user
