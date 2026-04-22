# ============================================================
# models/schemas.py
# Esquemas Pydantic para validación y documentación OpenAPI
# ============================================================

from pydantic import BaseModel, Field
from typing import Optional


# ----------------------------------------------------------
# RESPUESTA: Estadísticas de usuario
# ----------------------------------------------------------
class UserStats(BaseModel):
    uid: str = Field(
        ...,
        description="UID único del usuario en Firebase Auth",
        example="abc123xyz",
    )
    name: str = Field(
        ...,
        description="Nombre visible del usuario",
        example="Javier Medinilla",
    )
    total_posts: int = Field(
        ...,
        description="Número total de posts publicados por el usuario",
        example=12,
    )
    total_activities_joined: int = Field(
        ...,
        description="Número total de actividades en las que el usuario ha participado",
        example=8,
    )
    total_activities_organized: int = Field(
        ...,
        description="Número total de actividades organizadas por el usuario",
        example=3,
    )
    favorite_sport: Optional[str] = Field(
        None,
        description="Deporte más practicado por el usuario. Null si no tiene actividades.",
        example="Padel",
    )
    current_streak_days: int = Field(
        ...,
        description="Días consecutivos con actividad deportiva (racha actual)",
        example=5,
    )

    class Config:
        json_schema_extra = {
            "example": {
                "uid": "abc123xyz",
                "name": "Javier Medinilla",
                "total_posts": 12,
                "total_activities_joined": 8,
                "total_activities_organized": 3,
                "favorite_sport": "Padel",
                "current_streak_days": 5,
            }
        }


# ----------------------------------------------------------
# RESPUESTA: Entrada del ranking
# ----------------------------------------------------------
class RankingEntry(BaseModel):
    position: int = Field(
        ...,
        description="Posición en el ranking (1 = primero)",
        example=1,
    )
    uid: str = Field(
        ...,
        description="UID único del usuario",
        example="abc123xyz",
    )
    name: str = Field(
        ...,
        description="Nombre del usuario",
        example="Javier Medinilla",
    )
    total_activities: int = Field(
        ...,
        description="Total de actividades organizadas y completadas",
        example=11,
    )
    favorite_sport: Optional[str] = Field(
        None,
        description="Deporte más practicado por el usuario",
        example="Running",
    )
    profile_pic: Optional[str] = Field(
        None,
        description="Foto de perfil en Base64. Null si el usuario no tiene foto.",
        example=None,
    )

    class Config:
        json_schema_extra = {
            "example": {
                "position": 1,
                "uid": "abc123xyz",
                "name": "Javier Medinilla",
                "total_activities": 11,
                "favorite_sport": "Running",
                "profile_pic": None,
            }
        }


# ----------------------------------------------------------
# RESPUESTA: Estadísticas de una actividad
# ----------------------------------------------------------
class ActivityStats(BaseModel):
    activity_id: str = Field(
        ...,
        description="ID del documento de la actividad en Firestore",
        example="xK9mN2pQr",
    )
    title: str = Field(
        ...,
        description="Título de la actividad",
        example="Padel 2x2 tarde",
    )
    sport_type: str = Field(
        ...,
        description="Tipo de deporte de la actividad",
        example="Padel",
    )
    total_slots: int = Field(
        ...,
        description="Número total de plazas de la actividad",
        example=4,
    )
    occupied_slots: int = Field(
        ...,
        description="Número de plazas actualmente ocupadas",
        example=3,
    )
    occupancy_rate: float = Field(
        ...,
        description="Porcentaje de ocupación entre 0.0 y 1.0",
        example=0.75,
    )
    is_full: bool = Field(
        ...,
        description="True si la actividad está completa sin plazas libres",
        example=False,
    )

    class Config:
        json_schema_extra = {
            "example": {
                "activity_id": "xK9mN2pQr",
                "title": "Padel 2x2 tarde",
                "sport_type": "Padel",
                "total_slots": 4,
                "occupied_slots": 3,
                "occupancy_rate": 0.75,
                "is_full": False,
            }
        }


# ----------------------------------------------------------
# RESPUESTA: Recomendaciones de actividades
# ----------------------------------------------------------
class ActivityRecommendation(BaseModel):
    activity_id: str = Field(
        ...,
        description="ID del documento de la actividad en Firestore",
        example="xK9mN2pQr",
    )
    title: str = Field(
        ...,
        description="Título de la actividad",
        example="Running matutino en el parque",
    )
    sport_type: str = Field(
        ...,
        description="Tipo de deporte",
        example="Running",
    )
    location: str = Field(
        ...,
        description="Nombre de la ubicación del evento",
        example="Parque del Retiro, Madrid",
    )
    level: str = Field(
        ...,
        description="Nivel requerido para la actividad",
        example="Principiante",
    )
    occupied_slots: int = Field(
        ...,
        description="Plazas actualmente ocupadas",
        example=2,
    )
    total_slots: int = Field(
        ...,
        description="Total de plazas disponibles",
        example=10,
    )
    match_score: float = Field(
        ...,
        description="Puntuación de coincidencia con los deportes favoritos del usuario. 1.0 = coincidencia exacta, 0.5 = coincidencia parcial",
        example=1.0,
    )

    class Config:
        json_schema_extra = {
            "example": {
                "activity_id": "xK9mN2pQr",
                "title": "Running matutino en el parque",
                "sport_type": "Running",
                "location": "Parque del Retiro, Madrid",
                "level": "Principiante",
                "occupied_slots": 2,
                "total_slots": 10,
                "match_score": 1.0,
            }
        }


# ----------------------------------------------------------
# RESPUESTA: Envío de notificación push
# ----------------------------------------------------------
class NotificationResponse(BaseModel):
    status: str = Field(
        ...,
        description="Estado del envío: 'sent' si se envió, 'no_token' si el receptor no tiene token FCM registrado",
        example="sent",
    )
    message_id: Optional[str] = Field(
        None,
        description="ID del mensaje FCM devuelto por Firebase. Null si status es 'no_token'.",
        example="projects/fitcrew/messages/abc123",
    )
    message: Optional[str] = Field(
        None,
        description="Mensaje informativo. Solo presente cuando status es 'no_token'.",
        example=None,
    )

    class Config:
        json_schema_extra = {
            "example": {
                "status": "sent",
                "message_id": "projects/fitcrew/messages/abc123",
                "message": None,
            }
        }