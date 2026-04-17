# ============================================================
# routers/notifications.py
# Endpoint para enviar push notifications via FCM
# ============================================================

from fastapi import APIRouter, HTTPException, Header
from firebase_admin import auth, messaging
from firebase_config import db
from typing import Optional

router = APIRouter(prefix="/notifications", tags=["Notificaciones"])


def verify_token(authorization: str) -> str:
    """Verifica el Bearer token de Firebase y devuelve el UID."""
    try:
        token = authorization.replace("Bearer ", "")
        decoded = auth.verify_id_token(token)
        return decoded["uid"]
    except Exception:
        raise HTTPException(status_code=401, detail="Token inválido o expirado")


# ----------------------------------------------------------
# POST /notifications/send
# Envía una push notification a un usuario específico
# ----------------------------------------------------------
@router.post("/send")
async def send_notification(
    to_uid:        str,
    title:         str,
    body:          str,
    authorization: str = Header(...),
    data:          Optional[dict] = None,
):
    verify_token(authorization)

    try:
        # Se obtiene el token FCM del receptor
        user_doc = db.collection("users").document(to_uid).get()
        if not user_doc.exists:
            raise HTTPException(status_code=404, detail="Usuario no encontrado")

        fcm_token = user_doc.to_dict().get("fcmToken")
        if not fcm_token:
            # No bloqueamos si el usuario no tiene token
            return {"status": "no_token", "message": "Usuario sin token FCM"}

        # Se construlle el mensaje FCM
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data or {},
            token=fcm_token,
            android=messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(
                    channel_id="fitcrew_channel",
                    sound="default",
                    icon="ic_launcher",
                ),
            ),
            apns=messaging.APNSConfig(
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(sound="default"),
                ),
            ),
        )

        response = messaging.send(message)
        return {"status": "sent", "message_id": response}

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))