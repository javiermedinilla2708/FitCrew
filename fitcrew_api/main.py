# ============================================================
# main.py
# Punto de entrada de la API FitCrew
# Swagger disponible en /docs
# ReDoc disponible en /redoc
# ============================================================

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import stats, ranking, notifications

# ----------------------------------------------------------
# INICIALIZACIÓN DE LA APP
# ----------------------------------------------------------
app = FastAPI(
    title="FitCrew API",
    description="""
API REST para la aplicación móvil FitCrew — Red Social Deportiva.

## Autenticación
Todos los endpoints (excepto el health check) requieren un **Bearer token** de Firebase Auth
en el header `Authorization`:
```
Authorization: Bearer <firebase_id_token>
```

## Módulos
- **Stats**: Estadísticas de usuario y actividades
- **Ranking**: Clasificación global y por deporte
- **Notificaciones**: Envío de push notifications via FCM
    """,
    version="1.0.0",
    contact={
        "name": "Javier Medinilla",
        "url": "https://github.com/javiermedinilla2708/FitCrew",
    },
    license_info={
        "name": "MIT",
    },
)

# ----------------------------------------------------------
# CORS — permite llamadas desde Flutter
# ----------------------------------------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ----------------------------------------------------------
# ROUTERS
# ----------------------------------------------------------
app.include_router(stats.router)
app.include_router(ranking.router)
app.include_router(notifications.router)

# ----------------------------------------------------------
# HEALTH CHECK
# ----------------------------------------------------------
@app.get(
    "/",
    tags=["Health"],
    summary="Health check",
    description="Verifica que la API está activa y funcionando correctamente.",
    response_description="Estado de la API con nombre y versión.",
)
async def root():
    return {"status": "ok", "app": "FitCrew API", "version": "1.0.0"}