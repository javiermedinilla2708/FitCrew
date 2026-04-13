# ============================================================
# routers/stats.py
# Endpoints de estadísticas de usuario y actividades
# ============================================================

from fastapi import APIRouter, HTTPException, Header
from firebase_admin import auth, firestore
from models.schemas import UserStats, ActivityStats, ActivityRecommendation
from firebase_config import db
from typing import Optional

router = APIRouter(prefix="/stats", tags=["Estadísticas"])


# ----------------------------------------------------------
# HELPER: Verificar token de Firebase Auth
# ----------------------------------------------------------
def verify_token(authorization: str) -> str:
    """Verifica el Bearer token de Firebase y devuelve el UID."""
    try:
        token = authorization.replace("Bearer ", "")
        decoded = auth.verify_id_token(token)
        return decoded["uid"]
    except Exception:
        raise HTTPException(status_code=401, detail="Token inválido o expirado")


# ----------------------------------------------------------
# GET /stats/user/{uid}
# Devuelve las estadísticas de un usuario
# ----------------------------------------------------------
@router.get("/user/{uid}", response_model=UserStats)
async def get_user_stats(
    uid: str,
    authorization: str = Header(...),
):
    # --- Verificamos que el token es válido ---
    verify_token(authorization)

    try:
        # --- Datos del usuario ---
        user_doc = db.collection("users").document(uid).get()
        if not user_doc.exists:
            raise HTTPException(status_code=404, detail="Usuario no encontrado")

        user_data = user_doc.to_dict()

        # --- Total de posts ---
        posts = db.collection("posts").where("userId", "==", uid).get()
        total_posts = len(posts)

        # --- Actividades organizadas ---
        organized = (
            db.collection("activities").where("organizerId", "==", uid).get()
        )
        total_organized = len(organized)

        # --- Actividades en las que participó ---
        joined = (
            db.collection("activities")
            .where("participants", "array_contains", uid)
            .get()
        )
        total_joined = len(joined)

        # --- Deporte favorito (el más frecuente en actividades) ---
        sport_counts: dict[str, int] = {}
        for activity in joined:
            sport = activity.to_dict().get("sportType", "")
            if sport:
                sport_counts[sport] = sport_counts.get(sport, 0) + 1

        favorite_sport = (
            max(sport_counts, key=sport_counts.get) if sport_counts else None
        )

        # --- Racha de días consecutivos (simplificada) ---
        # Contamos días únicos con actividad en los últimos 30 días
        from datetime import datetime, timedelta
        now = datetime.utcnow()
        streak = 0
        for i in range(30):
            day = now - timedelta(days=i)
            day_start = day.replace(hour=0, minute=0, second=0, microsecond=0)
            day_end   = day.replace(hour=23, minute=59, second=59)
            activity_that_day = (
                db.collection("activities")
                .where("participants", "array_contains", uid)
                .where("date", ">=", day_start)
                .where("date", "<=", day_end)
                .get()
            )
            if activity_that_day:
                streak += 1
            else:
                break  # La racha se rompe

        return UserStats(
            uid=uid,
            name=user_data.get("name", "Usuario"),
            total_posts=total_posts,
            total_activities_joined=total_joined,
            total_activities_organized=total_organized,
            favorite_sport=favorite_sport,
            current_streak_days=streak,
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ----------------------------------------------------------
# GET /stats/activity/{activity_id}
# Devuelve las estadísticas de una actividad
# ----------------------------------------------------------
@router.get("/activity/{activity_id}", response_model=ActivityStats)
async def get_activity_stats(
    activity_id: str,
    authorization: str = Header(...),
):
    verify_token(authorization)

    try:
        doc = db.collection("activities").document(activity_id).get()
        if not doc.exists:
            raise HTTPException(status_code=404, detail="Actividad no encontrada")

        data = doc.to_dict()
        total    = data.get("totalSlots", 1)
        occupied = data.get("occupiedSlots", 0)

        return ActivityStats(
            activity_id=activity_id,
            title=data.get("title", ""),
            sport_type=data.get("sportType", ""),
            total_slots=total,
            occupied_slots=occupied,
            occupancy_rate=round(occupied / total, 2) if total > 0 else 0.0,
            is_full=occupied >= total,
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ----------------------------------------------------------
# GET /stats/recommendations/{uid}
# Devuelve actividades recomendadas según deportes favoritos
# ----------------------------------------------------------
@router.get("/recommendations/{uid}", response_model=list[ActivityRecommendation])
async def get_recommendations(
    uid: str,
    authorization: str = Header(...),
):
    verify_token(authorization)

    try:
        # --- Deportes favoritos del usuario ---
        user_doc = db.collection("users").document(uid).get()
        if not user_doc.exists:
            raise HTTPException(status_code=404, detail="Usuario no encontrado")

        favorite_sports: list[str] = user_doc.to_dict().get("favoriteSports", [])

        # --- Actividades que no están llenas ---
        activities = db.collection("activities").get()
        recommendations = []

        for doc in activities:
            data = doc.to_dict()
            sport      = data.get("sportType", "")
            occupied   = data.get("occupiedSlots", 0)
            total      = data.get("totalSlots", 1)
            organizer  = data.get("organizerId", "")
            participants = data.get("participants", [])

            # Excluimos actividades llenas, propias o en las que ya está
            if occupied >= total:
                continue
            if organizer == uid:
                continue
            if uid in participants:
                continue

            # Puntuación: 1.0 si el deporte coincide, 0.5 si no
            match_score = 1.0 if sport in favorite_sports else 0.5

            recommendations.append(
                ActivityRecommendation(
                    activity_id=doc.id,
                    title=data.get("title", ""),
                    sport_type=sport,
                    location=data.get("location", ""),
                    level=data.get("level", ""),
                    occupied_slots=occupied,
                    total_slots=total,
                    match_score=match_score,
                )
            )

        # Ordenamos por puntuación descendente
        recommendations.sort(key=lambda x: x.match_score, reverse=True)
        return recommendations[:10]  # Máximo 10 recomendaciones

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))