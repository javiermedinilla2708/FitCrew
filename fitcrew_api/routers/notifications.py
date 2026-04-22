# ============================================================
# routers/notifications.py
# Endpoint para enviar push notifications via FCM
# ============================================================

from fastapi import APIRouter, HTTPException, Header
from firebase_admin import auth, messaging
from firebase_config import db
from models.schemas import NotificationResponse
from typing import Optional

router = APIRouter(prefix="/notifications", tags=["Notificaciones"])


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
# POST /notifications/send
# ----------------------------------------------------------
@router.post(
    "/send",
    response_model=NotificationResponse,
    summary="Enviar push notification a un usuario",
    description="""
Envía una push notification via Firebase Cloud Messaging (FCM)
al dispositivo del usuario receptor.

**Flujo interno:**
1. Verifica el token Bearer del emisor
2. Obtiene el `fcmToken` del receptor desde Firestore
3. Si el receptor no tiene token FCM registrado devuelve `status: no_token`
4. Construye el mensaje FCM con configuración para Android e iOS
5. Envía el mensaje y devuelve el `message_id` de Firebase

**Configuración Android:**
- Canal: `fitcrew_channel` (importancia HIGH)
- Prioridad: `high`

**Configuración iOS:**
- Sound: `default`
- APNS configurado para alertas en primer y segundo plano
    """,
    response_description="Estado del envío con el message_id de Firebase si fue exitoso.",
    responses={
        200: {"description": "Notificación enviada correctamente o usuario sin token FCM"},
        401: {"description": "Token de autenticación inválido o expirado"},
        404: {"description": "Usuario receptor no encontrado en Firestore"},
        500: {"description": "Error interno al enviar la notificación"},
    },
)
async def send_notification(
    to_uid: str,
    title: str,
    body: str,
    authorization: str = Header(
        ...,
        description="Bearer token de Firebase Auth del emisor. Formato: 'Bearer <token>'",
    ),
    data: Optional[dict] = None,
):
    verify_token(authorization)

    try:
        user_doc = db.collection("users").document(to_uid).get()
        if not user_doc.exists:
            raise HTTPException(status_code=404, detail="Usuario no encontrado")

        fcm_token = user_doc.to_dict().get("fcmToken")
        if not fcm_token:
            return NotificationResponse(
                status="no_token",
                message="Usuario sin token FCM",
            )

        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
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
        return NotificationResponse(status="sent", message_id=response)

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))