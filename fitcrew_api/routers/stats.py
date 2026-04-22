# ============================================================
# routers/stats.py
# Endpoints de estadísticas de usuario y actividades
# ============================================================

from datetime import datetime, timedelta
from fastapi import APIRouter, HTTPException, Header
from firebase_admin import auth
from models.schemas import UserStats, ActivityStats, ActivityRecommendation
from firebase_config import db

router = APIRouter(prefix="/stats", tags=["Estadísticas"])


# ----------------------------------------------------------
# HELPER: Verificar token de Firebase Auth
# ----------------------------------------------------------
def verify_token(authorization: str) -> str:
    try:
        token = authorization.replace("Bearer ", "")
        decoded = auth.verify_id_token(token)
        return decoded["uid"]
    except Exception:
        raise HTTPException(status_code=401, detail="Token inválido o expirado")


# ----------------------------------------------------------
# GET /stats/user/{uid}
# ----------------------------------------------------------
@router.get(
    "/user/{uid}",
    response_model=UserStats,
    summary="Estadísticas de un usuario",
    description="""
Devuelve las estadísticas completas de un usuario:

- **total_posts**: posts publicados en el feed social
- **total_activities_joined**: actividades en las que ha participado
- **total_activities_organized**: actividades que ha creado
- **favorite_sport**: deporte más practicado según actividades
- **current_streak_days**: días consecutivos con actividad deportiva (máx. 30 días hacia atrás)

La racha se calcula en Python iterando los últimos 30 días y consultando las fechas
de las actividades del usuario, evitando así índices compuestos en Firestore.
    """,
    response_description="Objeto con todas las estadísticas del usuario.",
    responses={
        200: {"description": "Estadísticas obtenidas correctamente"},
        401: {"description": "Token de autenticación inválido o expirado"},
        404: {"description": "Usuario no encontrado en Firestore"},
        500: {"description": "Error interno del servidor"},
    },
)
async def get_user_stats(
    uid: str,
    authorization: str = Header(
        ...,
        description="Bearer token de Firebase Auth. Formato: 'Bearer <token>'",
    ),
):
    verify_token(authorization)

    try:
        user_doc = db.collection("users").document(uid).get()
        if not user_doc.exists:
            raise HTTPException(status_code=404, detail="Usuario no encontrado")

        user_data = user_doc.to_dict()

        posts           = db.collection("posts").where("userId", "==", uid).get()
        total_posts     = len(posts)

        organized       = db.collection("activities").where("organizerId", "==", uid).get()
        total_organized = len(organized)

        joined       = db.collection("activities").where("participants", "array_contains", uid).get()
        total_joined = len(joined)

        sport_counts: dict[str, int] = {}
        for activity in joined:
            sport = activity.to_dict().get("sportType", "")
            if sport:
                sport_counts[sport] = sport_counts.get(sport, 0) + 1

        favorite_sport = (
            max(sport_counts, key=sport_counts.get) if sport_counts else None
        )

        now    = datetime.utcnow()
        streak = 0
        days_with_activity: set[str] = set()

        for activity in joined:
            data = activity.to_dict()
            date = data.get("date")
            if date:
                try:
                    if hasattr(date, "todate"):
                        date = date.ToDatetime()
                    day_str = date.strftime("%Y-%m-%d")
                    days_with_activity.add(day_str)
                except Exception:
                    pass

        for i in range(30):
            day     = now - timedelta(days=i)
            day_str = day.strftime("%Y-%m-%d")
            if day_str in days_with_activity:
                streak += 1
            else:
                break

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
# ----------------------------------------------------------
@router.get(
    "/activity/{activity_id}",
    response_model=ActivityStats,
    summary="Estadísticas de una actividad",
    description="""
Devuelve las estadísticas de ocupación de una actividad específica:

- **occupancy_rate**: valor entre 0.0 y 1.0 que indica el porcentaje de ocupación
- **is_full**: true si no quedan plazas disponibles
    """,
    response_description="Objeto con las estadísticas de ocupación de la actividad.",
    responses={
        200: {"description": "Estadísticas obtenidas correctamente"},
        401: {"description": "Token de autenticación inválido o expirado"},
        404: {"description": "Actividad no encontrada en Firestore"},
        500: {"description": "Error interno del servidor"},
    },
)
async def get_activity_stats(
    activity_id: str,
    authorization: str = Header(
        ...,
        description="Bearer token de Firebase Auth. Formato: 'Bearer <token>'",
    ),
):
    verify_token(authorization)

    try:
        doc = db.collection("activities").document(activity_id).get()
        if not doc.exists:
            raise HTTPException(status_code=404, detail="Actividad no encontrada")

        data     = doc.to_dict()
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
# ----------------------------------------------------------
@router.get(
    "/recommendations/{uid}",
    response_model=list[ActivityRecommendation],
    summary="Actividades recomendadas para un usuario",
    description="""
Devuelve hasta 10 actividades recomendadas para el usuario según sus deportes favoritos.

**Criterios de filtrado:**
- Se excluyen actividades llenas
- Se excluyen actividades organizadas por el propio usuario
- Se excluyen actividades en las que ya está apuntado

**Puntuación (match_score):**
- `1.0` — el deporte coincide con los favoritos del usuario
- `0.5` — el deporte no coincide pero la actividad está disponible

Los resultados se ordenan por `match_score` de mayor a menor.
    """,
    response_description="Lista de hasta 10 actividades recomendadas ordenadas por relevancia.",
    responses={
        200: {"description": "Recomendaciones obtenidas correctamente"},
        401: {"description": "Token de autenticación inválido o expirado"},
        404: {"description": "Usuario no encontrado en Firestore"},
        500: {"description": "Error interno del servidor"},
    },
)
async def get_recommendations(
    uid: str,
    authorization: str = Header(
        ...,
        description="Bearer token de Firebase Auth. Formato: 'Bearer <token>'",
    ),
):
    verify_token(authorization)

    try:
        user_doc = db.collection("users").document(uid).get()
        if not user_doc.exists:
            raise HTTPException(status_code=404, detail="Usuario no encontrado")

        favorite_sports: list[str] = user_doc.to_dict().get("favoriteSports", [])
        activities      = db.collection("activities").get()
        recommendations = []

        for doc in activities:
            data         = doc.to_dict()
            sport        = data.get("sportType", "")
            occupied     = data.get("occupiedSlots", 0)
            total        = data.get("totalSlots", 1)
            organizer    = data.get("organizerId", "")
            participants = data.get("participants", [])

            if occupied >= total:
                continue
            if organizer == uid:
                continue
            if uid in participants:
                continue

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

        recommendations.sort(key=lambda x: x.match_score, reverse=True)
        return recommendations[:10]

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))