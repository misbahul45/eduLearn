import logging
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.db.models import PredictionHistory, User
from app.schemas.prediction import (
    PredictionAnalysisResponse,
    PredictionHistoryItem,
    PredictionHistoryResponse,
    PredictionResponse,
)

logger = logging.getLogger(__name__)

router = APIRouter(tags=["predictions"])


@router.get("/api/v1/predictions/latest", response_model=PredictionResponse)
async def get_latest_prediction(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(PredictionHistory)
        .where(PredictionHistory.user_id == current_user.id)
        .order_by(PredictionHistory.created_at.desc())
        .limit(1)
    )
    pred = result.scalar_one_or_none()
    if not pred:
        return PredictionResponse(
            label="-",
            probability=0.0,
            class_scores={},
        )

    return PredictionResponse(
        label=pred.predicted_label,
        probability=pred.confidence,
        class_scores=pred.class_scores or {},
    )


@router.get("/api/v1/predictions/history", response_model=PredictionHistoryResponse)
async def get_prediction_history(
    days: int = 30,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    since = datetime.now(timezone.utc) - timedelta(days=days)
    result = await db.execute(
        select(PredictionHistory)
        .where(
            PredictionHistory.user_id == current_user.id,
            PredictionHistory.created_at >= since,
        )
        .order_by(PredictionHistory.created_at.desc())
    )
    items = [
        PredictionHistoryItem(
            id=str(p.id),
            probability=p.confidence,
            label=p.predicted_label,
            created_at=p.created_at.isoformat(),
        )
        for p in result.scalars().all()
    ]
    return PredictionHistoryResponse(predictions=items)


@router.get("/api/v1/predictions/analysis", response_model=PredictionAnalysisResponse)
async def get_prediction_analysis(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    total = await db.scalar(
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
    failed = (total or 0) - (passed or 0)
    avg_prob = await db.scalar(
        select(func.avg(PredictionHistory.probability)).where(
            PredictionHistory.user_id == current_user.id
        )
    )

    return PredictionAnalysisResponse(
        total_predictions=total or 0,
        passed_count=passed or 0,
        failed_count=failed,
        pass_rate=(passed or 0) / (total or 1) * 100,
        avg_probability=round(float(avg_prob or 0.0), 4),
    )
