from datetime import datetime, timezone

from pydantic import BaseModel, Field


class PredictionRequest(BaseModel):
    features: list[float]


class PredictionResponse(BaseModel):
    label: str
    probability: float
    class_scores: dict[str, float]


class PredictionHistoryItem(BaseModel):
    id: str
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


class ClassScore(BaseModel):
    label: str
    score: float


class PredictionResult(BaseModel):
    predicted_label: str
    confidence: float
    class_scores: list[ClassScore]
    model_name: str
    model_version: str
    input_features_used: list[str]
    generated_at: datetime


class StudentSignals(BaseModel):
    time_spent_minutes: float | None = None
    video_completion_rate: float | None = None
    video_watched_count: int | None = None
    quiz_attempts: int | None = None
    quiz_score_avg: float | None = None
    quiz_score_max: float | None = None
    forum_posts: int | None = None
    forum_replies: int | None = None
    assignment_submitted: int | None = None
    assignment_score_avg: float | None = None
    login_count: int | None = None
    days_active: int | None = None
    study_streak: int | None = None
    education_level: str | None = None
    learning_path_type: str | None = None
