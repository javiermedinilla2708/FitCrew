# ============================================================
# routers/ranking.py
# Endpoints de ranking global y por deporte
# ============================================================

from fastapi import APIRouter, HTTPException, Header
from firebase_admin import auth
from models.schemas import RankingEntry
from firebase_config import db

router = APIRouter(prefix="/ranking", tags=["Ranking"])


# ----------------------------------------------------------
# HELPER: Verificar token
# ----------------------------------------------------------
def verify_token(authorization: str) -> str:
    try:
        token = authorization.replace("Bearer ", "")
        decoded = auth.verify_id_token(token)
        return decoded["uid"]
    except Exception:
        raise HTTPException(status_code=401, detail="Token inválido o expirado")


# ----------------------------------------------------------
# GET /ranking/global
# ----------------------------------------------------------
@router.get(
    "/global",
    response_model=list[RankingEntry],
    summary="Ranking global de usuarios",
    description="""
Devuelve el top 10 de usuarios ordenados por número total de actividades
(organizadas + participadas).

Cada entrada incluye la posición, nombre, total de actividades,
deporte favorito y foto de perfil si la tiene.
    """,
    response_description="Lista de hasta 10 usuarios ordenados de mayor a menor actividad.",
    responses={
        200: {"description": "Ranking obtenido correctamente"},
        401: {"description": "Token de autenticación inválido o expirado"},
        500: {"description": "Error interno del servidor"},
    },
)
async def get_global_ranking(
    authorization: str = Header(
        ...,
        description="Bearer token de Firebase Auth. Formato: 'Bearer <token>'",
    ),
):
    verify_token(authorization)

    try:
        users   = db.collection("users").get()
        ranking = []

        for user_doc in users:
            uid       = user_doc.id
            user_data = user_doc.to_dict()

            organized        = db.collection("activities").where("organizerId", "==", uid).get()
            joined           = db.collection("activities").where("participants", "array_contains", uid).get()
            total_activities = len(organized) + len(joined)

            sport_counts: dict[str, int] = {}
            for activity in joined:
                sport = activity.to_dict().get("sportType", "")
                if sport:
                    sport_counts[sport] = sport_counts.get(sport, 0) + 1

            favorite_sport = (
                max(sport_counts, key=sport_counts.get)
                if sport_counts else None
            )

            ranking.append({
                "uid":              uid,
                "name":             user_data.get("name", "Usuario"),
                "total_activities": total_activities,
                "favorite_sport":   favorite_sport,
                "profile_pic":      user_data.get("profilePic"),
            })

        ranking.sort(key=lambda x: x["total_activities"], reverse=True)

        return [
            RankingEntry(position=i + 1, **entry)
            for i, entry in enumerate(ranking[:10])
        ]

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ----------------------------------------------------------
# GET /ranking/sport/{sport}
# ----------------------------------------------------------
@router.get(
    "/sport/{sport}",
    response_model=list[RankingEntry],
    summary="Ranking por deporte específico",
    description="""
Devuelve el top 10 de usuarios en un deporte concreto, ordenados
por número de actividades de ese deporte (organizadas + participadas).

Solo aparecen usuarios con al menos una actividad del deporte indicado.

**Ejemplo de valores para `sport`:** `Padel`, `Running`, `Basket`, `Ciclismo`
    """,
    response_description="Lista de hasta 10 usuarios ordenados por actividad en el deporte indicado.",
    responses={
        200: {"description": "Ranking por deporte obtenido correctamente"},
        401: {"description": "Token de autenticación inválido o expirado"},
        500: {"description": "Error interno del servidor"},
    },
)
async def get_sport_ranking(
    sport: str,
    authorization: str = Header(
        ...,
        description="Bearer token de Firebase Auth. Formato: 'Bearer <token>'",
    ),
):
    verify_token(authorization)

    try:
        users   = db.collection("users").get()
        ranking = []

        for user_doc in users:
            uid       = user_doc.id
            user_data = user_doc.to_dict()

            joined    = db.collection("activities").where("participants", "array_contains", uid).where("sportType", "==", sport).get()
            organized = db.collection("activities").where("organizerId", "==", uid).where("sportType", "==", sport).get()

            total = len(joined) + len(organized)
            if total == 0:
                continue

            ranking.append({
                "uid":              uid,
                "name":             user_data.get("name", "Usuario"),
                "total_activities": total,
                "favorite_sport":   sport,
                "profile_pic":      user_data.get("profilePic"),
            })

        ranking.sort(key=lambda x: x["total_activities"], reverse=True)

        return [
            RankingEntry(position=i + 1, **entry)
            for i, entry in enumerate(ranking[:10])
        ]

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))