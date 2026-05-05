# FitCrew

Red social deportiva móvil desarrollada con Flutter y Firebase como Trabajo de Fin de Grado del Ciclo Superior de Desarrollo de Aplicaciones Multiplataforma (DAM) en el IES Portada Alta, curso 2025-2026.

---

## Descripción

FitCrew es una aplicación móvil que conecta a personas con intereses deportivos en común. Permite compartir entrenamientos, organizar actividades deportivas en un mapa interactivo, seguir a otros usuarios y competir en un ranking de actividad.

---

## Tecnologías utilizadas

### Frontend
- Flutter 3.x (Dart)
- Arquitectura MVVM con Provider
- flutter_map con tiles de CartoDB para el mapa interactivo
- sqflite para historial de búsquedas local (SQLite)
- flutter_local_notifications para notificaciones locales
- another_flushbar para notificaciones en pantalla

### Backend
- Firebase Authentication (email/contraseña y Google Sign-In)
- Cloud Firestore como base de datos en tiempo real
- Firebase Cloud Messaging (FCM) para notificaciones push
- API REST propia desarrollada en Python con FastAPI, desplegada en Railway

---

## Funcionalidades principales

### Feed social
- Publicación de posts con foto del entrenamiento
- Selección de deporte y nivel de intensidad
- Añadir ubicación con autocompletado mediante la API de Nominatim
- Etiquetar a otros usuarios en el post
- Sistema de likes y comentarios en tiempo real
- Feed ordenado por fecha con actualización automática

### Mapa de actividades
- Mapa interactivo con marcadores personalizados por deporte
- Filtro por radio de búsqueda (1 a 50 km)
- Filtro por deportes favoritos del usuario
- Crear actividades con nombre, ubicación, hora, deporte, nivel y plazas
- Apuntarse y desapuntarse de actividades
- Eliminación automática de actividades pasadas 24 horas

### Sistema de seguimiento
- Perfiles públicos y privados
- Envío, aceptación y rechazo de solicitudes de seguimiento
- Seguimiento directo mutuo sin solicitud cuando procede
- Pantalla de seguidores y seguidos con buscador
- Sugerencias de usuarios con deportes en común

### Notificaciones
- Notificaciones push via FCM
- Notificaciones en pantalla de likes, comentarios, solicitudes de seguimiento y actividades
- Badge de no leídas en tiempo real
- Marcar como leída, eliminar individualmente o borrar todas

### Perfil de usuario
- Foto de perfil, nombre y bio editables
- Estadísticas de posts, seguidores y seguidos en tiempo real
- Círculo de entrenos mensual con datos de la API
- Barras de progreso de actividades por deporte
- Galería de logros publicados con visor de imagen a pantalla completa
- Configuración de privacidad, seguridad y preferencias

### Ranking
- Ranking global de usuarios más activos
- Filtrado por deporte

### Búsqueda
- Búsqueda de usuarios por nombre
- Historial de búsquedas recientes almacenado en SQLite
- Sugerencias por deportes en común

### Autenticación
- Registro e inicio de sesión con email y contraseña
- Inicio de sesión con Google
- Verificación de email al registrarse
- Recuperación de contraseña por correo
- Reautenticación antes de eliminar la cuenta
- Eliminación completa de cuenta y datos asociados

---

## Estructura del proyecto
fitcrew/
├── lib/
│   ├── core/
│   │   └── utils/
│   │       └── app_constants.dart
│   ├── models/
│   │   ├── app_notification.dart
│   │   ├── notification_type.dart
│   │   ├── post.dart
│   │   └── sport_activity.dart
│   ├── screens/
│   │   ├── auth/
│   │   ├── activities/
│   │   ├── filters/
│   │   ├── home/
│   │   ├── notifications/
│   │   ├── post/
│   │   ├── profile/
│   │   ├── ranking/
│   │   ├── search/
│   │   ├── settings/
│   │   ├── tutorial/
│   │   └── welcome/
│   ├── services/
│   │   ├── activity_service.dart
│   │   ├── api_service.dart
│   │   ├── auth_services.dart
│   │   ├── follow_services.dart
│   │   ├── notification_service.dart
│   │   ├── push_notification_service.dart
│   │   ├── search_history_service.dart
│   │   └── user_services.dart
│   ├── viewmodels/
│   │   ├── activity_view_model.dart
│   │   ├── auth_viewmodel.dart
│   │   ├── filter_viewmodel.dart
│   │   └── post_viewmodel.dart
│   └── main.dart
├── android/
├── ios/
└── fitcrew_api/
├── main.py
├── models.py
├── routes/
└── requirements.txt

---

## API REST

La API está desarrollada en Python con FastAPI y desplegada en Railway.

URL base: `https://fitcrew-production-5fe4.up.railway.app`

### Endpoints principales

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | /users/{uid}/stats | Estadísticas del usuario |
| GET | /ranking | Ranking global de usuarios |
| GET | /ranking/{sport} | Ranking filtrado por deporte |

---

## Instalación y configuración

### Requisitos previos
- Flutter SDK 3.x
- Dart SDK
- Android Studio o VS Code
- Cuenta de Firebase
- Python 3.10 o superior (para la API)

### Pasos

1. Clona el repositorio:
git clone https://github.com/javiermedinilla2708/FitCrew

2. Instala las dependencias de Flutter:
flutter pub get

3. Configura Firebase:
   - Crea un proyecto en Firebase Console
   - Descarga el archivo google-services.json y colócalo en android/app/
   - Habilita Authentication, Firestore y Cloud Messaging

4. Configura las reglas de Firestore según el archivo de reglas incluido en el repositorio.

5. Ejecuta la aplicación:
flutter run

### API local (opcional)
cd fitcrew_api
pip install -r requirements.txt
uvicorn main:app --reload

---

## Colecciones de Firestore

| Colección | Descripción |
|-----------|-------------|
| users | Datos de perfil, deportes favoritos y token FCM |
| posts | Publicaciones del feed con subcolecciones de likes y comentarios |
| activities | Actividades deportivas en el mapa |
| notifications | Notificaciones de la aplicación |
| follow_requests | Solicitudes de seguimiento entre usuarios |

---

## Autor

Javier Medinilla Domínguez  
IES Portada Alta  
Ciclo Superior de Desarrollo de Aplicaciones Multiplataforma  
Curso 2025-2026