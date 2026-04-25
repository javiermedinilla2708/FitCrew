// ============================================================
// lib/services/user_service.dart
// Servicio que gestiona las operaciones CRUD sobre el documento
// de usuario en Firestore. Es utilizado por AuthService para
// mantener separación de responsabilidades entre autenticación
// y gestión de datos de perfil.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ----------------------------------------------------------
  // CREAR DOCUMENTO DE USUARIO
  // Se llama tras el registro exitoso en Firebase Auth.
  // Inicializa el documento con campos por defecto:
  //   - favoriteSports: lista vacía (se rellena en el setup)
  //   - profilePic: null
  //   - bio: cadena vacía
  //   - isPrivate: false (perfil público por defecto)
  //   - notificationsOn: true (notificaciones activadas)
  //   - language: es (español por defecto)
  //   - createdAt: timestamp del servidor para consistencia
  // ----------------------------------------------------------
  Future<void> createUserData(String uid, String name, String email) async {
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'favoriteSports': [],
      'createdAt': FieldValue.serverTimestamp(),
      'profilePic': null,
      'bio': "",
      'isPrivate': false,
      'notificationsOn': true,
      'language': 'es',
    });
  }

  // ----------------------------------------------------------
  // OBTENER DEPORTES FAVORITOS DEL USUARIO
  // ----------------------------------------------------------
  Future<List<String>> getUserSports(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return List<String>.from(doc.get('favoriteSports') ?? []);
    }
    return [];
  }

  // ----------------------------------------------------------
  // ACTUALIZAR DEPORTES FAVORITOS DEL USUARIO
  // ----------------------------------------------------------
  Future<void> updateFavoriteSports(String uid, List<String> sports) async {
    await _db.collection('users').doc(uid).update({'favoriteSports': sports});
  }

  // ----------------------------------------------------------
  // MARCAR CONFIGURACIÓN INICIAL COMO COMPLETADA
  // ----------------------------------------------------------
  Future<void> updateSetupComplete(String uid) async {
    await _db.collection('users').doc(uid).update({'setupComplete': true});
  }

  // ----------------------------------------------------------
  // ELIMINAR DOCUMENTO DE USUARIO
  // ----------------------------------------------------------
  Future<void> deleteUserData(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  // ----------------------------------------------------------
  // ACTUALIZAR PRIVACIDAD
  // true = perfil privado, false = perfil público
  // ----------------------------------------------------------
  Future<void> updatePrivacy(String uid, bool isPrivate) async {
    await _db.collection('users').doc(uid).update({'isPrivate': isPrivate});
  }

  // ----------------------------------------------------------
  // ACTUALIZAR PREFERENCIA DE NOTIFICACIONES
  // true = notificaciones activadas, false = desactivadas
  // ----------------------------------------------------------
  Future<void> updateNotificationsEnabled(String uid, bool enabled) async {
    await _db.collection('users').doc(uid).update({'notificationsOn': enabled});
  }

  // ----------------------------------------------------------
  // ACTUALIZAR IDIOMA
  // Guarda el código de idioma seleccionado por el usuario.
  // El cambio se aplica en el próximo inicio de sesión.
  // ----------------------------------------------------------
  Future<void> updateLanguage(String uid, String languageCode) async {
    await _db.collection('users').doc(uid).update({'language': languageCode});
  }

  // ----------------------------------------------------------
  // OBTENER DATOS COMPLETOS DE UN USUARIO
  // Usado para cargar el perfil ajeno en UserProfileScreen
  // ----------------------------------------------------------
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) return doc.data();
    return null;
  }
}
