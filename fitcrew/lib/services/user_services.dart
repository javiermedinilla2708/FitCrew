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
  //   - profilePic: null (pendiente de implementar con Storage)
  //   - bio: cadena vacía
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
    });
  }

  // ----------------------------------------------------------
  // OBTENER DEPORTES FAVORITOS DEL USUARIO
  // Devuelve la lista de deportes favoritos del usuario.
  // Si el documento no existe o el campo está vacío,
  // devuelve una lista vacía para evitar null safety issues.
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
  // Sobrescribe la lista completa de deportes favoritos.
  // Se llama desde la pantalla de configuración inicial
  // y desde el perfil si el usuario edita sus preferencias.
  // ----------------------------------------------------------
  Future<void> updateFavoriteSports(String uid, List<String> sports) async {
    await _db.collection('users').doc(uid).update({'favoriteSports': sports});
  }

  // ----------------------------------------------------------
  // MARCAR CONFIGURACIÓN INICIAL COMO COMPLETADA
  // Se llama al finalizar el flujo de onboarding (selección
  // de deportes favoritos). Permite a la app saber si debe
  // redirigir al usuario al setup o directamente al home.
  // ----------------------------------------------------------
  Future<void> updateSetupComplete(String uid) async {
    await _db.collection('users').doc(uid).update({'setupComplete': true});
  }

  // ----------------------------------------------------------
  // ELIMINAR DOCUMENTO DE USUARIO
  // Se llama como parte del proceso de eliminación de cuenta
  // en AuthService, después de eliminar los posts del usuario
  // y antes de eliminar la cuenta de Firebase Auth.
  // ----------------------------------------------------------
  Future<void> deleteUserData(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }
}
