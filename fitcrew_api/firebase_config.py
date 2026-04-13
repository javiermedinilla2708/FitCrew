# ============================================================
# firebase_config.py
# Inicialización del SDK de Firebase Admin
# Lee las credenciales desde variable de entorno en producción
# ============================================================

import os
import json
import firebase_admin
from firebase_admin import credentials, firestore

# ----------------------------------------------------------
# CREDENCIALES
# En local lee el archivo JSON
# En Railway lee la variable de entorno FIREBASE_CREDENTIALS
# ----------------------------------------------------------
if not firebase_admin._apps:
    firebase_credentials = os.environ.get("FIREBASE_CREDENTIALS")

    if firebase_credentials:
        # --- Producción: lee desde variable de entorno ---
        cred_dict = json.loads(firebase_credentials)
        cred = credentials.Certificate(cred_dict)
    else:
        # --- Local: lee desde archivo ---
        cred = credentials.Certificate("serviceAccountKey.json")

    firebase_admin.initialize_app(cred)

# --- Cliente de Firestore ---
db = firestore.client()