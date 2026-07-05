from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class StudentSignals(BaseModel):
    age: Optional[int] = Field(None, ge=14, le=65)
    gender: Optional[str] = Field(None, description="Male/Female/Non-binary")
    education_level: Optional[str] = Field(
        None, description="High School/Some College/Bachelor's/Graduate/Doctoral"
    )
    country: Optional[str] = None
    employment_status: Optional[str] = Field(
        None, description="Student/Employed Full-time/Employed Part-time/Self-employed/Unemployed/Retired/Homemaker"
    )
    prior_online_courses: Optional[int] = Field(None, ge=0)
    digital_literacy_score: Optional[float] = Field(None, ge=0, le=10)
    app_category: Optional[str] = Field(
        None, description="Test Prep/Language Learning/Mathematics/Soft Skills/Science/Programming/Art & Design/Business/Productivity/Health & Fitness"
    )
    daily_app_minutes: Optional[float] = Field(None, ge=0)
    session_count_weekly: Optional[int] = Field(None, ge=0)
    app_completion_rate: Optional[float] = Field(None, ge=0, le=100)
    in_app_quiz_score: Optional[float] = Field(None, ge=0, le=100)
    gamification_engagement: Optional[float] = Field(None, ge=0)
    skill_pre_score: Optional[float] = Field(None, ge=0, le=100)
    skill_post_score: Optional[float] = Field(None, ge=0, le=100)
    essay_topic_category: Optional[str] = Field(
        None, description="Argumentative/Descriptive/Expository/Narrative/Persuasive"
    )
    essay_word_count: Optional[int] = Field(None, ge=0)
    essay_grammar_errors: Optional[int] = Field(None, ge=0)
    essay_vocabulary_richness: Optional[float] = Field(None, ge=0, le=1)
    essay_coherence_score: Optional[float] = Field(None, ge=0, le=1)
    mooc_platform: Optional[str] = Field(
        None, description="Coursera/FutureLearn/Skillshare/edX/Udacity/Canvas"
    )
    course_category: Optional[str] = Field(
        None, description="Personal Development/Technology/Business & Finance/Health & Medicine/Arts & Humanities/Data Science/Engineering/Social Sciences"
    )
    course_duration_weeks: Optional[int] = Field(None, ge=1, le=20)
    video_completion_pct: Optional[float] = Field(None, ge=0, le=100)
    assignment_submission_rate: Optional[float] = Field(None, ge=0, le=100)
    forum_posts: Optional[float] = Field(None, ge=0)
    peer_review_given: Optional[float] = Field(None, ge=0)
    learning_path_type: Optional[str] = Field(None, description="Linear/Branched/Adaptive")
    content_difficulty_avg: Optional[float] = Field(None, ge=1, le=5)
    content_recommendations_followed: Optional[float] = Field(None, ge=0, le=100)
    knowledge_gaps_identified: Optional[int] = Field(None, ge=0)
    remediation_modules_completed: Optional[int] = Field(None, ge=0)
    time_to_mastery_hours: Optional[float] = Field(None, ge=0)
    mastery_score: Optional[float] = Field(None, ge=0, le=100)
    learning_efficiency_score: Optional[float] = Field(None, ge=0)
    total_learning_hours: Optional[float] = Field(None, ge=0)
    engagement_consistency: Optional[float] = Field(None, ge=0, le=1)


class ClassScore(BaseModel):
    label: str
    score: float


class PredictionResult(BaseModel):
    predicted_label: str
    confidence: float
    confidence_interpretation: str
    class_scores: list[ClassScore]
    model_name: str = "Deep MLP (TensorFlow)"
    model_version: str = "1.0.0"
    input_features_used: list[str]
    recommendations: list[str] = Field(default_factory=list)
    risk_factors: list[str] = Field(default_factory=list)
    generated_at: datetime = Field(default_factory=lambda: datetime.now())


class PredictionRequest(BaseModel):
    signals: StudentSignals


class PredictionResponse(BaseModel):
    predicted_label: str
    confidence: float
    confidence_interpretation: str
    class_scores: list[ClassScore]
    model_name: str
    recommendations: list[str]
    risk_factors: list[str]


class PredictionHistoryItem(BaseModel):
    id: str
    predicted_label: str
    confidence: float
    created_at: str


class PredictionHistoryResponse(BaseModel):
    predictions: list[PredictionHistoryItem]


class PredictionAnalysisResponse(BaseModel):
    total_predictions: int
    passed_count: int
    failed_count: int
    pass_rate: float
    avg_confidence: float