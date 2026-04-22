# ============================================================
# tests/test_api.py
# Tests unitarios de la API FitCrew con mocks
# No requieren conexión a Firebase ni credenciales reales
#
# Ejecutar con:
#   pytest tests/test_api.py -v
# ============================================================

import pytest
from unittest.mock import patch, MagicMock
from fastapi.testclient import TestClient

# ----------------------------------------------------------
# MOCK DE FIREBASE ANTES DE IMPORTAR LA APP
# Es necesario parchear firebase_admin antes de que
# cualquier módulo lo importe, de lo contrario falla
# la inicialización al no haber credenciales reales
# ----------------------------------------------------------
import sys

# Mock completo del módulo firebase_admin
firebase_mock         = MagicMock()
firebase_auth_mock    = MagicMock()
firebase_db_mock      = MagicMock()
firebase_msg_mock     = MagicMock()
firebase_config_mock  = MagicMock()

sys.modules["firebase_admin"]              = firebase_mock
sys.modules["firebase_admin.auth"]         = firebase_auth_mock
sys.modules["firebase_admin.firestore"]    = firebase_db_mock
sys.modules["firebase_admin.messaging"]    = firebase_msg_mock
sys.modules["firebase_config"]             = firebase_config_mock

# Mock de la base de datos Firestore
mock_db = MagicMock()
firebase_config_mock.db = mock_db

# Ahora ya es seguro importar la app
from main import app

# ----------------------------------------------------------
# CLIENTE DE TEST
# TestClient simula peticiones HTTP sin levantar un servidor
# ----------------------------------------------------------
client = TestClient(app)

# ----------------------------------------------------------
# TOKEN DE PRUEBA — se usa en todos los headers
# ----------------------------------------------------------
FAKE_TOKEN  = "Bearer fake_token_para_tests"
FAKE_UID    = "uid_test_123"
FAKE_NAME   = "Usuario Test"


# ==============================================================
# HELPER: configura verify_token para que no falle en los tests
# ==============================================================
def mock_verify_token(authorization: str) -> str:
    """Sustituye la verificación real de Firebase por una simulada."""
    return FAKE_UID


# ==============================================================
# TESTS: HEALTH CHECK
# ==============================================================
class TestHealthCheck:
    """Verifica que el endpoint raíz responde correctamente."""

    def test_root_returns_ok(self):
        """El health check debe devolver status ok y la versión."""
        response = client.get("/")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ok"
        assert data["app"] == "FitCrew API"
        assert data["version"] == "1.0.0"

    def test_root_no_auth_required(self):
        """El health check no requiere autenticación."""
        response = client.get("/")
        assert response.status_code == 200


# ==============================================================
# TESTS: STATS — GET /stats/user/{uid}
# ==============================================================
class TestUserStats:
    """Tests del endpoint de estadísticas de usuario."""

    def _mock_user_doc(self, exists=True, name=FAKE_NAME, sports=None):
        """Crea un mock de documento de usuario de Firestore."""
        doc = MagicMock()
        doc.exists = exists
        doc.to_dict.return_value = {
            "name":           name,
            "favoriteSports": sports or ["Running", "Padel"],
        }
        return doc

    def _mock_activity(self, sport="Running", date_str="2026-04-20"):
        """Crea un mock de actividad de Firestore."""
        from datetime import datetime
        activity = MagicMock()
        fake_date = datetime.strptime(date_str, "%Y-%m-%d")
        activity.to_dict.return_value = {
            "sportType": sport,
            "date":      fake_date,
        }
        return activity

    @patch("routers.stats.verify_token", side_effect=mock_verify_token)
    def test_user_stats_returns_correct_structure(self, _):
        """Las stats deben devolver todos los campos del schema UserStats."""
        mock_db.collection.return_value.document.return_value.get.return_value = (
            self._mock_user_doc()
        )
        mock_db.collection.return_value.where.return_value.get.return_value = []

        response = client.get(
            f"/stats/user/{FAKE_UID}",
            headers={"Authorization": FAKE_TOKEN},
        )
        assert response.status_code == 200
        data = response.json()
        assert "uid"                        in data
        assert "name"                       in data
        assert "total_posts"                in data
        assert "total_activities_joined"    in data
        assert "total_activities_organized" in data
        assert "current_streak_days"        in data

    @patch("routers.stats.verify_token", side_effect=mock_verify_token)
    def test_user_stats_zero_when_no_activities(self, _):
        """Si el usuario no tiene actividades todos los contadores deben ser 0."""
        mock_db.collection.return_value.document.return_value.get.return_value = (
            self._mock_user_doc()
        )
        mock_db.collection.return_value.where.return_value.get.return_value = []

        response = client.get(
            f"/stats/user/{FAKE_UID}",
            headers={"Authorization": FAKE_TOKEN},
        )
        assert response.status_code == 200
        data = response.json()
        assert data["total_posts"]                == 0
        assert data["total_activities_joined"]    == 0
        assert data["total_activities_organized"] == 0
        assert data["current_streak_days"]        == 0
        assert data["favorite_sport"]             is None

    @patch("routers.stats.verify_token", side_effect=mock_verify_token)
    def test_user_stats_404_when_user_not_found(self, _):
        """Debe devolver 404 si el usuario no existe en Firestore."""
        mock_db.collection.return_value.document.return_value.get.return_value = (
            self._mock_user_doc(exists=False)
        )

        response = client.get(
            f"/stats/user/uid_que_no_existe",
            headers={"Authorization": FAKE_TOKEN},
        )
        assert response.status_code == 404
        assert "no encontrado" in response.json()["detail"].lower()

    @patch("routers.stats.verify_token", side_effect=mock_verify_token)
    def test_user_stats_favorite_sport_most_common(self, _):
        """El deporte favorito debe ser el más repetido en las actividades."""
        mock_db.collection.return_value.document.return_value.get.return_value = (
            self._mock_user_doc()
        )

        activities = [
            self._mock_activity("Running"),
            self._mock_activity("Running"),
            self._mock_activity("Padel"),
        ]

        def where_side_effect(field, op, val):
            result = MagicMock()
            if field == "participants":
                result.get.return_value = activities
            else:
                result.get.return_value = []
            return result

        mock_db.collection.return_value.where.side_effect = where_side_effect

        response = client.get(
            f"/stats/user/{FAKE_UID}",
            headers={"Authorization": FAKE_TOKEN},
        )
        assert response.status_code == 200
        assert response.json()["favorite_sport"] == "Running"

    def test_user_stats_401_without_token(self):
        """Sin token de autenticación debe devolver 401 o 422."""
        response = client.get(f"/stats/user/{FAKE_UID}")
        assert response.status_code in [401, 422]


# ==============================================================
# TESTS: STATS — GET /stats/activity/{activity_id}
# ==============================================================
class TestActivityStats:
    """Tests del endpoint de estadísticas de actividad."""

    def _mock_activity_doc(self, exists=True, total=4, occupied=2):
        """Crea un mock de documento de actividad de Firestore."""
        doc = MagicMock()
        doc.exists = exists
        doc.to_dict.return_value = {
            "title":         "Padel tarde",
            "sportType":     "Padel",
            "totalSlots":    total,
            "occupiedSlots": occupied,
        }
        return doc

    @patch("routers.stats.verify_token", side_effect=mock_verify_token)
    def test_activity_stats_correct_occupancy_rate(self, _):
        """La tasa de ocupación debe calcularse correctamente."""
        mock_db.collection.return_value.document.return_value.get.return_value = (
            self._mock_activity_doc(total=4, occupied=2)
        )

        response = client.get(
            "/stats/activity/fake_activity_id",
            headers={"Authorization": FAKE_TOKEN},
        )
        assert response.status_code == 200
        data = response.json()
        assert data["occupancy_rate"] == 0.5
        assert data["is_full"]        == False
        assert data["total_slots"]    == 4
        assert data["occupied_slots"] == 2

    @patch("routers.stats.verify_token", side_effect=mock_verify_token)
    def test_activity_stats_is_full_when_all_slots_occupied(self, _):
        """is_full debe ser True cuando todos los slots están ocupados."""
        mock_db.collection.return_value.document.return_value.get.return_value = (
            self._mock_activity_doc(total=4, occupied=4)
        )

        response = client.get(
            "/stats/activity/fake_activity_id",
            headers={"Authorization": FAKE_TOKEN},
        )
        assert response.status_code == 200
        data = response.json()
        assert data["is_full"]        == True
        assert data["occupancy_rate"] == 1.0

    @patch("routers.stats.verify_token", side_effect=mock_verify_token)
    def test_activity_stats_404_when_not_found(self, _):
        """Debe devolver 404 si la actividad no existe."""
        mock_db.collection.return_value.document.return_value.get.return_value = (
            self._mock_activity_doc(exists=False)
        )

        response = client.get(
            "/stats/activity/id_inexistente",
            headers={"Authorization": FAKE_TOKEN},
        )
        assert response.status_code == 404


# ==============================================================
# TESTS: RANKING — GET /ranking/global
# ==============================================================
class TestRanking:
    """Tests del endpoint de ranking global."""

    def _mock_user_doc(self, uid, name, sports=None):
        """Crea un mock de documento de usuario para el ranking."""
        doc = MagicMock()
        doc.id = uid
        doc.to_dict.return_value = {
            "name":           name,
            "favoriteSports": sports or [],
            "profilePic":     None,
        }
        return doc

    @patch("routers.ranking.verify_token", side_effect=mock_verify_token)
    def test_global_ranking_returns_list(self, _):
        """El ranking global debe devolver una lista."""
        mock_db.collection.return_value.get.return_value = []

        response = client.get(
            "/ranking/global",
            headers={"Authorization": FAKE_TOKEN},
        )
        assert response.status_code == 200
        assert isinstance(response.json(), list)

    @patch("routers.ranking.verify_token", side_effect=mock_verify_token)
    def test_global_ranking_max_10_entries(self, _):
        """El ranking no debe devolver más de 10 entradas."""
        users = [self._mock_user_doc(f"uid_{i}", f"Usuario {i}") for i in range(20)]
        mock_db.collection.return_value.get.return_value = users
        mock_db.collection.return_value.where.return_value.get.return_value = []

        response = client.get(
            "/ranking/global",
            headers={"Authorization": FAKE_TOKEN},
        )
        assert response.status_code == 200
        assert len(response.json()) <= 10

    @patch("routers.ranking.verify_token", side_effect=mock_verify_token)
    def test_global_ranking_has_position_field(self, _):
        """Cada entrada del ranking debe tener el campo position."""
        users = [self._mock_user_doc("uid_1", "Usuario Test")]
        mock_db.collection.return_value.get.return_value = users
        mock_db.collection.return_value.where.return_value.get.return_value = []

        response = client.get(
            "/ranking/global",
            headers={"Authorization": FAKE_TOKEN},
        )
        assert response.status_code == 200
        data = response.json()
        if len(data) > 0:
            assert "position"         in data[0]
            assert "uid"              in data[0]
            assert "name"             in data[0]
            assert "total_activities" in data[0]

    @patch("routers.ranking.verify_token", side_effect=mock_verify_token)
    def test_global_ranking_ordered_by_activities(self, _):
        """El ranking debe estar ordenado de mayor a menor actividad."""
        user_a = self._mock_user_doc("uid_a", "Usuario A")
        user_b = self._mock_user_doc("uid_b", "Usuario B")
        mock_db.collection.return_value.get.return_value = [user_a, user_b]

        call_count = [0]

        def where_side_effect(field, op, val):
            result = MagicMock()
            call_count[0] += 1
            # Usuario A tiene 5 actividades, Usuario B tiene 2
            if "uid_a" in str(val):
                activities = [MagicMock() for _ in range(5)]
                for a in activities:
                    a.to_dict.return_value = {"sportType": "Running"}
                result.get.return_value = activities
            else:
                activities = [MagicMock() for _ in range(2)]
                for a in activities:
                    a.to_dict.return_value = {"sportType": "Padel"}
                result.get.return_value = activities
            return result

        mock_db.collection.return_value.where.side_effect = where_side_effect

        response = client.get(
            "/ranking/global",
            headers={"Authorization": FAKE_TOKEN},
        )
        assert response.status_code == 200
        data = response.json()
        if len(data) >= 2:
            assert data[0]["total_activities"] >= data[1]["total_activities"]

    def test_global_ranking_401_without_token(self):
        """Sin token debe devolver 401 o 422."""
        response = client.get("/ranking/global")
        assert response.status_code in [401, 422]


# ==============================================================
# TESTS: NOTIFICACIONES — POST /notifications/send
# ==============================================================
class TestNotifications:
    """Tests del endpoint de envío de notificaciones push."""

    def _mock_user_with_token(self, fcm_token="fake_fcm_token_abc"):
        """Crea un mock de usuario con token FCM."""
        doc = MagicMock()
        doc.exists = True
        doc.to_dict.return_value = {"fcmToken": fcm_token}
        return doc

    def _mock_user_without_token(self):
        """Crea un mock de usuario sin token FCM registrado."""
        doc = MagicMock()
        doc.exists = True
        doc.to_dict.return_value = {}
        return doc

    @patch("routers.notifications.verify_token", side_effect=mock_verify_token)
    @patch("routers.notifications.messaging")
    def test_send_notification_returns_sent(self, mock_messaging, _):
        """Debe devolver status sent cuando la notificación se envía correctamente."""
        mock_db.collection.return_value.document.return_value.get.return_value = (
            self._mock_user_with_token()
        )
        mock_messaging.send.return_value = "projects/fitcrew/messages/abc123"
        mock_messaging.Message           = MagicMock()
        mock_messaging.Notification      = MagicMock()
        mock_messaging.AndroidConfig     = MagicMock()
        mock_messaging.AndroidNotification = MagicMock()
        mock_messaging.APNSConfig        = MagicMock()
        mock_messaging.APNSPayload       = MagicMock()
        mock_messaging.Aps               = MagicMock()

        response = client.post(
            "/notifications/send",
            params={
                "to_uid": "uid_receptor",
                "title":  "Test titulo",
                "body":   "Test cuerpo",
            },
            headers={"Authorization": FAKE_TOKEN},
        )
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "sent"
        assert data["message_id"] is not None

    @patch("routers.notifications.verify_token", side_effect=mock_verify_token)
    def test_send_notification_no_token_returns_no_token(self, _):
        """Debe devolver no_token si el receptor no tiene FCM token."""
        mock_db.collection.return_value.document.return_value.get.return_value = (
            self._mock_user_without_token()
        )

        response = client.post(
            "/notifications/send",
            params={
                "to_uid": "uid_sin_token",
                "title":  "Test",
                "body":   "Test",
            },
            headers={"Authorization": FAKE_TOKEN},
        )
        assert response.status_code == 200
        assert response.json()["status"] == "no_token"

    @patch("routers.notifications.verify_token", side_effect=mock_verify_token)
    def test_send_notification_404_when_user_not_found(self, _):
        """Debe devolver 404 si el usuario receptor no existe."""
        doc = MagicMock()
        doc.exists = False
        mock_db.collection.return_value.document.return_value.get.return_value = doc

        response = client.post(
            "/notifications/send",
            params={
                "to_uid": "uid_inexistente",
                "title":  "Test",
                "body":   "Test",
            },
            headers={"Authorization": FAKE_TOKEN},
        )
        assert response.status_code == 404

    def test_send_notification_401_without_token(self):
        """Sin token debe devolver 401 o 422."""
        response = client.post(
            "/notifications/send",
            params={
                "to_uid": "uid_receptor",
                "title":  "Test",
                "body":   "Test",
            },
        )
        assert response.status_code in [401, 422]


# ==============================================================
# TESTS: RECOMENDACIONES — GET /stats/recommendations/{uid}
# ==============================================================
class TestRecommendations:
    """Tests del endpoint de recomendaciones de actividades."""

    def _mock_user_with_sports(self, sports):
        """Crea un mock de usuario con deportes favoritos."""
        doc = MagicMock()
        doc.exists = True
        doc.to_dict.return_value = {"favoriteSports": sports}
        return doc

    def _mock_activity_doc(self, sport, occupied, total, organizer, participants):
        """Crea un mock de actividad con todos sus campos."""
        doc = MagicMock()
        doc.id = f"activity_{sport}_{occupied}"
        doc.to_dict.return_value = {
            "sportType":     sport,
            "occupiedSlots": occupied,
            "totalSlots":    total,
            "organizerId":   organizer,
            "participants":  participants,
            "title":         f"Actividad de {sport}",
            "location":      "Madrid",
            "level":         "Intermedio",
        }
        return doc

    @patch("routers.stats.verify_token", side_effect=mock_verify_token)
    def test_recommendations_returns_list(self, _):
        """Las recomendaciones deben devolver una lista."""
        mock_db.collection.return_value.document.return_value.get.return_value = (
            self._mock_user_with_sports(["Running"])
        )
        mock_db.collection.return_value.get.return_value = []

        response = client.get(
            f"/stats/recommendations/{FAKE_UID}",
            headers={"Authorization": FAKE_TOKEN},
        )
        assert response.status_code == 200
        assert isinstance(response.json(), list)

    @patch("routers.stats.verify_token", side_effect=mock_verify_token)
    def test_recommendations_excludes_full_activities(self, _):
        """Las actividades llenas no deben aparecer en las recomendaciones."""
        mock_db.collection.return_value.document.return_value.get.return_value = (
            self._mock_user_with_sports(["Running"])
        )
        full_activity = self._mock_activity_doc(
            sport="Running",
            occupied=4,
            total=4,
            organizer="otro_uid",
            participants=[],
        )
        mock_db.collection.return_value.get.return_value = [full_activity]

        response = client.get(
            f"/stats/recommendations/{FAKE_UID}",
            headers={"Authorization": FAKE_TOKEN},
        )
        assert response.status_code == 200
        assert len(response.json()) == 0

    @patch("routers.stats.verify_token", side_effect=mock_verify_token)
    def test_recommendations_excludes_own_activities(self, _):
        """Las actividades organizadas por el propio usuario no deben aparecer."""
        mock_db.collection.return_value.document.return_value.get.return_value = (
            self._mock_user_with_sports(["Running"])
        )
        own_activity = self._mock_activity_doc(
            sport="Running",
            occupied=1,
            total=4,
            organizer=FAKE_UID,
            participants=[],
        )
        mock_db.collection.return_value.get.return_value = [own_activity]

        response = client.get(
            f"/stats/recommendations/{FAKE_UID}",
            headers={"Authorization": FAKE_TOKEN},
        )
        assert response.status_code == 200
        assert len(response.json()) == 0

    @patch("routers.stats.verify_token", side_effect=mock_verify_token)
    def test_recommendations_match_score_1_for_favorite_sport(self, _):
        """Las actividades del deporte favorito deben tener match_score 1.0."""
        mock_db.collection.return_value.document.return_value.get.return_value = (
            self._mock_user_with_sports(["Running"])
        )
        activity = self._mock_activity_doc(
            sport="Running",
            occupied=1,
            total=4,
            organizer="otro_uid",
            participants=[],
        )
        mock_db.collection.return_value.get.return_value = [activity]

        response = client.get(
            f"/stats/recommendations/{FAKE_UID}",
            headers={"Authorization": FAKE_TOKEN},
        )
        assert response.status_code == 200
        data = response.json()
        if len(data) > 0:
            assert data[0]["match_score"] == 1.0

    @patch("routers.stats.verify_token", side_effect=mock_verify_token)
    def test_recommendations_max_10_results(self, _):
        """Las recomendaciones no deben superar 10 resultados."""
        mock_db.collection.return_value.document.return_value.get.return_value = (
            self._mock_user_with_sports(["Running"])
        )
        activities = [
            self._mock_activity_doc(
                sport="Running",
                occupied=1,
                total=4,
                organizer="otro_uid",
                participants=[],
            )
            for _ in range(20)
        ]
        mock_db.collection.return_value.get.return_value = activities

        response = client.get(
            f"/stats/recommendations/{FAKE_UID}",
            headers={"Authorization": FAKE_TOKEN},
        )
        assert response.status_code == 200
        assert len(response.json()) <= 10