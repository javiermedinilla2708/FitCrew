# ============================================================
# models/schemas.py
# Esquemas Pydantic para validación de datos
# ============================================================

from pydantic import BaseModel
from typing import Optional


# ----------------------------------------------------------
# RESPUESTA: Estadísticas de usuario
# ----------------------------------------------------------
class UserStats(BaseModel):
    uid: str
    name: str
    total_posts: int
    total_activities_joined: int
    total_activities_organized: int
    favorite_sport: Optional[str]
    current_streak_days: int


# ----------------------------------------------------------
# RESPUESTA: Entrada del ranking
# ----------------------------------------------------------
class RankingEntry(BaseModel):
    position: int
    uid: str
    name: str
    total_activities: int
    favorite_sport: Optional[str]
    profile_pic: Optional[str]


# ----------------------------------------------------------
# RESPUESTA: Estadísticas de una actividad
# ----------------------------------------------------------
class ActivityStats(BaseModel):
    activity_id: str
    title: str
    sport_type: str
    total_slots: int
    occupied_slots: int
    occupancy_rate: float
    is_full: bool


# ----------------------------------------------------------
# RESPUESTA: Recomendaciones
# ----------------------------------------------------------
class ActivityRecommendation(BaseModel):
    activity_id: str
    title: str
    sport_type: str
    location: str
    level: str
    occupied_slots: int
    total_slots: int
    match_score: float  # 0.0 a 1.0 según coincidencia de deportes