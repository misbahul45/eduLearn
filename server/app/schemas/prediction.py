from pydantic import BaseModel


class PredictionRequest(BaseModel):
    features: list[float]


class PredictionResponse(BaseModel):
    label: str
    probability: float
    class_scores: dict[str, float]


class PredictionHistoryItem(BaseModel):
    id: int
    probability: float
    label: str
    created_at: str


class PredictionHistoryResponse(BaseModel):
    predictions: list[PredictionHistoryItem]


class PredictionAnalysisResponse(BaseModel):
    total_predictions: int
    passed_count: int
    failed_count: int
    pass_rate: float
    avg_probability: float
