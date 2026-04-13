# ============================================================
# main.py
# Punto de entrada de la API FitCrew
# ============================================================

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import stats, ranking

# ----------------------------------------------------------
# INICIALIZACIÓN DE LA APP
# ----------------------------------------------------------
app = FastAPI(
    title="FitCrew API",
    description="API REST para estadísticas y ranking de FitCrew",
    version="1.0.0",
)

# ----------------------------------------------------------
# CORS — permite llamadas desde Flutter (cualquier origen
# en desarrollo, restringir en producción)
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

# ----------------------------------------------------------
# HEALTH CHECK
# ----------------------------------------------------------
@app.get("/", tags=["Health"])
async def root():
    return {"status": "ok", "app": "FitCrew API", "version": "1.0.0"}