import logging

from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.db.models import Conversation, PredictionHistory, User
from app.schemas.auth import UserResponse

logger = logging.getLogger(__name__)

router = APIRouter(tags=["users"])


@router.get("/api/v1/users/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user)):
    return UserResponse(
        id=str(current_user.id),
        name=current_user.name,
        email=current_user.email,
    )


@router.get("/api/v1/users/stats")
async def get_stats(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    conv_count = await db.scalar(
        select(func.count(Conversation.id)).where(
            Conversation.user_id == current_user.id
        )
    )

    pred_count = await db.scalar(
        select(func.count(PredictionHistory.id)).where(
            PredictionHistory.user_id == current_user.id
        )
    )

    passed = await db.scalar(
        select(func.count(PredictionHistory.id)).where(
            PredictionHistory.user_id == current_user.id,
            PredictionHistory.predicted_label == "Lulus",
        )
    )

    return {
        "total_conversations": conv_count or 0,
        "total_predictions": pred_count or 0,
        "passed_predictions": passed or 0,
        "name": current_user.name,
        "email": current_user.email,
        "role": current_user.role,
    }
