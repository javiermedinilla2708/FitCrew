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
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final UserService _userService = UserService();

  // ----------------------------------------------------------
  // REGISTRO CON EMAIL Y CONTRASENA
  // Crea la cuenta en Firebase Auth y el documento en Firestore
  // con los datos iniciales del usuario
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

        await user.sendEmailVerification();
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    } catch (e) {
      throw "Error general: ${e.toString()}";
    }
  }

  // ----------------------------------------------------------
  // LOGIN CON EMAIL Y CONTRASENA
  // Autentica al usuario en Firebase Auth con sus credenciales
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
  // LOGIN CON GOOGLE
  // Abre el selector de cuenta de Google del dispositivo.
  // Si el usuario ya existe en Firestore no modifica sus datos.
  // Si es nuevo crea el documento en Firestore.
  // Devuelve un Map con el User y un bool isNewUser.
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw "Inicio de sesion cancelado";
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      final user = result.user;

      if (user == null) throw "Error al autenticar con Google";

      // Comprobar si el usuario ya existe en Firestore
      final doc = await _db.collection('users').doc(user.uid).get();
      final bool isNewUser = !doc.exists;

      if (isNewUser) {
        await _userService.createUserData(
          user.uid,
          user.displayName ?? "Usuario FitCrew",
          user.email ?? "",
        );
      }

      return {'user': user, 'isNewUser': isNewUser};
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains("cancelado") || msg.contains("canceled")) {
        throw "Inicio de sesion cancelado";
      }
      throw "Error al iniciar sesion con Google";
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
  // CERRAR SESION
  // Cierra sesion tanto en Firebase como en Google para
  // limpiar la cache y forzar seleccion de cuenta en el
  // proximo inicio de sesion con Google
  // ----------------------------------------------------------
  Future<void> signOut() async {
    try {
      // Cerrar sesion de Google si estaba activa para limpiar
      // la cache del dispositivo y evitar auto-login
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      debugPrint("Error al cerrar sesion: $e");
    }
  }

  // ----------------------------------------------------------
  // REAUTENTICAR USUARIO
  // Necesario antes de operaciones sensibles como eliminar
  // la cuenta cuando han pasado mas de 5 minutos desde el login
  // ----------------------------------------------------------
  Future<bool> reauthenticate(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return false;

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      debugPrint("Error reautenticando: $e");
      return false;
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
  //   8.  Eliminar deportes favoritos del usuario (FilterScreen)
  //   9.  Eliminar documento del usuario en Firestore
  //   10. Desconectar sesion de Google si aplica
  //   11. Eliminar cuenta de Firebase Auth
  //
  // Requiere login reciente — Firebase lanza requires-recent-login
  // si han pasado mas de 5 minutos desde la ultima autenticacion
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
      // las actividades quedarian huerfanas en el mapa
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
      // Los usuarios que le seguian o a los que seguia
      // deben tambien actualizar sus subcolecciones
      // --------------------------------------------------

      // Eliminar de following de cada usuario que este seguia
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

      // Eliminar de followers de cada usuario que le seguia
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
      // Paso 8 — Eliminar deportes favoritos seleccionados
      // en FilterScreen. Se borran del campo favoriteSports
      // del documento del usuario antes de eliminarlo.
      // Tambien se elimina el flag setupComplete para que
      // si el usuario vuelve a registrarse pase por el
      // onboarding de deportes correctamente.
      // --------------------------------------------------
      try {
        await _db.collection('users').doc(uid).update({
          'favoriteSports': [],
          'setupComplete': false,
        });
      } catch (e) {
        debugPrint("Error limpiando deportes favoritos: $e");
      }

      // --------------------------------------------------
      // Paso 9 — Eliminar documento del usuario en Firestore
      // --------------------------------------------------
      await _userService.deleteUserData(uid);

      // --------------------------------------------------
      // Paso 10 — Desconectar sesion de Google si el usuario
      // entro con Google para limpiar la cache del dispositivo
      // y forzar la seleccion de cuenta en el proximo login
      // disconnect revoca permisos completamente a diferencia
      // de signOut que solo cierra la sesion activa
      // --------------------------------------------------
      try {
        final googleSignIn = GoogleSignIn();
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.disconnect();
        }
      } catch (e) {
        debugPrint("Google disconnect omitido: $e");
      }

      // --------------------------------------------------
      // Paso 11 — Eliminar la cuenta de Firebase Auth
      // Debe ser el ultimo paso porque tras esto el usuario
      // pierde acceso a Firestore
      // --------------------------------------------------
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw "Por seguridad, debes haber iniciado sesion recientemente para borrar tu cuenta.";
      }
      rethrow;
    } catch (e) {
      debugPrint("Error deleteUserAccount: $e");
      throw "No se pudo eliminar la cuenta.";
    }
  }

  // ----------------------------------------------------------
  // MAPEO DE ERRORES DE FIREBASE AUTH
  // Traduce los codigos de error tecnicos de Firebase a mensajes
  // comprensibles para el usuario en espanol
  // ----------------------------------------------------------
  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return "Este correo electronico ya esta registrado.";
      case 'weak-password':
        return "La contrasena es demasiado debil.";
      case 'invalid-email':
        return "El formato del correo electronico no es valido.";
      case 'user-not-found':
        return "No existe ningun usuario con este correo.";
      case 'wrong-password':
        return "La contrasena es incorrecta.";
      case 'user-disabled':
        return "Esta cuenta ha sido deshabilitada.";
      case 'invalid-credential':
        return "Credenciales incorrectas o expiradas.";
      default:
        return "Ocurrio un error inesperado.";
    }
  }
}
