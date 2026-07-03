import logging

from fastapi import APIRouter, Depends, HTTPException

from app.schemas.prediction import (
    PredictionAnalysisResponse,
    PredictionHistoryResponse,
    PredictionResponse,
)

logger = logging.getLogger(__name__)

router = APIRouter(tags=["predictions"])


@router.get("/api/v1/predictions/latest", response_model=PredictionResponse)
async def get_latest_prediction():
    raise HTTPException(status_code=501, detail="Not implemented")


@router.get("/api/v1/predictions/history", response_model=PredictionHistoryResponse)
async def get_prediction_history(days: int = 30):
    raise HTTPException(status_code=501, detail="Not implemented")


@router.get("/api/v1/predictions/analysis", response_model=PredictionAnalysisResponse)
async def get_prediction_analysis():
    raise HTTPException(status_code=501, detail="Not implemented")
