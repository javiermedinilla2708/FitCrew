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
# Top 10 usuarios por número de actividades totales
# ----------------------------------------------------------
@router.get("/global", response_model=list[RankingEntry])
async def get_global_ranking(authorization: str = Header(...)):
    verify_token(authorization)

    try:
        users = db.collection("users").get()
        ranking = []

        for user_doc in users:
            uid       = user_doc.id
            user_data = user_doc.to_dict()

            # Actividades organizadas + en las que participó
            organized = (
                db.collection("activities").where("organizerId", "==", uid).get()
            )
            joined = (
                db.collection("activities")
                .where("participants", "array_contains", uid)
                .get()
            )
            total_activities = len(organized) + len(joined)

            # Deporte más practicado
            sport_counts: dict[str, int] = {}
            for activity in joined:
                sport = activity.to_dict().get("sportType", "")
                if sport:
                    sport_counts[sport] = sport_counts.get(sport, 0) + 1

            favorite_sport = (
                max(sport_counts, key=sport_counts.get)
                if sport_counts
                else None
            )

            ranking.append({
                "uid": uid,
                "name": user_data.get("name", "Usuario"),
                "total_activities": total_activities,
                "favorite_sport": favorite_sport,
                "profile_pic": user_data.get("profilePic"),
            })

        # Ordenamos por total de actividades
        ranking.sort(key=lambda x: x["total_activities"], reverse=True)

        # Añadimos la posición
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
# Top 10 usuarios por deporte específico
# ----------------------------------------------------------
@router.get("/sport/{sport}", response_model=list[RankingEntry])
async def get_sport_ranking(
    sport: str,
    authorization: str = Header(...),
):
    verify_token(authorization)

    try:
        users = db.collection("users").get()
        ranking = []

        for user_doc in users:
            uid       = user_doc.id
            user_data = user_doc.to_dict()

            # Solo actividades de ese deporte
            joined = (
                db.collection("activities")
                .where("participants", "array_contains", uid)
                .where("sportType", "==", sport)
                .get()
            )
            organized = (
                db.collection("activities")
                .where("organizerId", "==", uid)
                .where("sportType", "==", sport)
                .get()
            )

            total = len(joined) + len(organized)
            if total == 0:
                continue

            ranking.append({
                "uid": uid,
                "name": user_data.get("name", "Usuario"),
                "total_activities": total,
                "favorite_sport": sport,
                "profile_pic": user_data.get("profilePic"),
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