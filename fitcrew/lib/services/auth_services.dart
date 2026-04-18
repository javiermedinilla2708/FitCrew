// ============================================================
// lib/services/auth_service.dart
// Servicio de autenticación que gestiona el registro, login,
// cierre de sesión y eliminación de cuenta usando Firebase Auth.
// Delega la gestión de datos de usuario en UserService.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcrew/services/push_notification_service.dart';
import 'package:fitcrew/services/user_services.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final UserService _userService = UserService();

  // ----------------------------------------------------------
  // REGISTRO CON EMAIL Y CONTRASEÑA
  // ----------------------------------------------------------
  Future<User?> registerWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();

      final result = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final user = result.user;
      if (user != null) {
        await user.updateDisplayName(name);
        await _userService.createUserData(user.uid, name, normalizedEmail);
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    } catch (e) {
      throw "Error general: ${e.toString()}";
    }
  }

  // ----------------------------------------------------------
  // LOGIN CON EMAIL Y CONTRASEÑA
  // ----------------------------------------------------------
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();

      final result = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    } catch (e) {
      throw "Error inesperado al intentar entrar.";
    }
  }

  // ----------------------------------------------------------
  // OBTENER DEPORTES FAVORITOS DEL USUARIO
  // ----------------------------------------------------------
  Future<List<String>> getUserSports(String uid) async {
    return _userService.getUserSports(uid);
  }

  // ----------------------------------------------------------
  // ACTUALIZAR DEPORTES FAVORITOS DEL USUARIO
  // ----------------------------------------------------------
  Future<void> updateFavoriteSports(String uid, List<String> sports) async {
    await _userService.updateFavoriteSports(uid, sports);
  }

  // ----------------------------------------------------------
  // CERRAR SESIÓN
  // ----------------------------------------------------------
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint("Error al cerrar sesión: $e");
    }
  }

  // ----------------------------------------------------------
  // ELIMINAR CUENTA DE USUARIO — borrado completo
  // Proceso en orden:
  //   1.  Limpiar token FCM del dispositivo
  //   2.  Eliminar posts del usuario
  //   3.  Eliminar actividades organizadas por el usuario
  //   4.  Eliminar notificaciones enviadas y recibidas
  //   5.  Eliminar solicitudes de seguimiento enviadas y recibidas
  //   6.  Eliminar subcolecciones followers y following
  //   7.  Desapuntarse de actividades donde participa
  //   8.  Eliminar documento del usuario en Firestore
  //   9.  Eliminar cuenta de Firebase Auth
  //
  // Requiere login reciente — Firebase lanza requires-recent-login
  // si han pasado más de 5 minutos desde la última autenticación
  // ----------------------------------------------------------
  Future<void> deleteUserAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      final uid = user.uid;

      // --------------------------------------------------
      // Paso 1 — Limpiar token FCM
      // --------------------------------------------------
      await PushNotificationService.clearToken();

      // --------------------------------------------------
      // Paso 2 — Eliminar todos los posts del usuario
      // --------------------------------------------------
      final postsQuery = await _db
          .collection('posts')
          .where('userId', isEqualTo: uid)
          .get();

      final batchPosts = _db.batch();
      for (final doc in postsQuery.docs) {
        batchPosts.delete(doc.reference);
      }
      await batchPosts.commit();

      // --------------------------------------------------
      // Paso 3 — Eliminar actividades organizadas por el usuario
      // Se borran completamente ya que sin organizador
      // las actividades quedarían huérfanas en el mapa
      // --------------------------------------------------
      final activitiesOrganized = await _db
          .collection('activities')
          .where('organizerId', isEqualTo: uid)
          .get();

      final batchActivities = _db.batch();
      for (final doc in activitiesOrganized.docs) {
        batchActivities.delete(doc.reference);
      }
      await batchActivities.commit();

      // --------------------------------------------------
      // Paso 4 — Eliminar notificaciones recibidas (toUid)
      //          y enviadas (fromUid)
      // --------------------------------------------------
      final notifsReceived = await _db
          .collection('notifications')
          .where('toUid', isEqualTo: uid)
          .get();

      final notifsSent = await _db
          .collection('notifications')
          .where('fromUid', isEqualTo: uid)
          .get();

      final batchNotifs = _db.batch();
      for (final doc in notifsReceived.docs) {
        batchNotifs.delete(doc.reference);
      }
      for (final doc in notifsSent.docs) {
        batchNotifs.delete(doc.reference);
      }
      await batchNotifs.commit();

      // --------------------------------------------------
      // Paso 5 — Eliminar solicitudes de seguimiento
      //          enviadas (fromUid) y recibidas (toUid)
      // --------------------------------------------------
      final requestsSent = await _db
          .collection('follow_requests')
          .where('fromUid', isEqualTo: uid)
          .get();

      final requestsReceived = await _db
          .collection('follow_requests')
          .where('toUid', isEqualTo: uid)
          .get();

      final batchRequests = _db.batch();
      for (final doc in requestsSent.docs) {
        batchRequests.delete(doc.reference);
      }
      for (final doc in requestsReceived.docs) {
        batchRequests.delete(doc.reference);
      }
      await batchRequests.commit();

      // --------------------------------------------------
      // Paso 6 — Eliminar subcolecciones followers y following
      // Los usuarios que le seguían o a los que seguía
      // deben también actualizar sus subcolecciones
      // --------------------------------------------------

      // Eliminar de following de cada usuario que este seguía
      final followingDocs = await _db
          .collection('users')
          .doc(uid)
          .collection('following')
          .get();

      final batchFollowing = _db.batch();
      for (final doc in followingDocs.docs) {
        final followedUid = doc.id;
        batchFollowing.delete(
          _db
              .collection('users')
              .doc(followedUid)
              .collection('followers')
              .doc(uid),
        );
        batchFollowing.delete(doc.reference);
      }
      await batchFollowing.commit();

      // Eliminar de followers de cada usuario que le seguía
      final followersDocs = await _db
          .collection('users')
          .doc(uid)
          .collection('followers')
          .get();

      final batchFollowers = _db.batch();
      for (final doc in followersDocs.docs) {
        final followerUid = doc.id;
        batchFollowers.delete(
          _db
              .collection('users')
              .doc(followerUid)
              .collection('following')
              .doc(uid),
        );
        batchFollowers.delete(doc.reference);
      }
      await batchFollowers.commit();

      // --------------------------------------------------
      // Paso 7 — Desapuntarse de actividades donde participa
      // Decrementa occupiedSlots y elimina al usuario
      // de la lista de participants en cada actividad
      // --------------------------------------------------
      final activitiesJoined = await _db
          .collection('activities')
          .where('participants', arrayContains: uid)
          .get();

      for (final doc in activitiesJoined.docs) {
        final data = doc.data();
        final occupied = (data['occupiedSlots'] as int? ?? 1);
        final participants = List<String>.from(data['participants'] ?? []);
        participants.remove(uid);

        await doc.reference.update({
          'occupiedSlots': occupied > 0 ? occupied - 1 : 0,
          'participants': participants,
        });
      }

      // --------------------------------------------------
      // Paso 8 — Eliminar documento del usuario en Firestore
      // --------------------------------------------------
      await _userService.deleteUserData(uid);

      // --------------------------------------------------
      // Paso 9 — Eliminar la cuenta de Firebase Auth
      // Debe ser el último paso porque tras esto el usuario
      // pierde acceso a Firestore
      // --------------------------------------------------
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw "Por seguridad, debes haber iniciado sesión recientemente para borrar tu cuenta.";
      }
      rethrow;
    } catch (e) {
      throw "No se pudo eliminar la cuenta.";
    }
  }

  // ----------------------------------------------------------
  // MAPEO DE ERRORES DE FIREBASE AUTH
  // Traduce los códigos de error técnicos de Firebase a mensajes
  // comprensibles para el usuario en español
  // ----------------------------------------------------------
  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return "Este correo electrónico ya está registrado.";
      case 'weak-password':
        return "La contraseña es demasiado débil.";
      case 'invalid-email':
        return "El formato del correo electrónico no es válido.";
      case 'user-not-found':
        return "No existe ningún usuario con este correo.";
      case 'wrong-password':
        return "La contraseña es incorrecta.";
      case 'user-disabled':
        return "Esta cuenta ha sido deshabilitada.";
      case 'invalid-credential':
        return "Credenciales incorrectas o expiradas.";
      default:
        return "Ocurrió un error inesperado.";
    }
  }
}
