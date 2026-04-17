// ============================================================
// lib/services/auth_service.dart
// Servicio de autenticación que gestiona el registro, login,
// cierre de sesión y eliminación de cuenta usando Firebase Auth.
// Delega la gestión de datos de usuario en UserService.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcrew/services/user_services.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final UserService _userService = UserService();

  // ----------------------------------------------------------
  // REGISTRO CON EMAIL Y CONTRASEÑA
  // Crea la cuenta en Firebase Auth, actualiza el displayName
  // y delega la creación del documento de usuario en UserService
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
        // Actualiza el nombre visible en Firebase Auth
        await user.updateDisplayName(name);

        // Crea el documento del usuario en Firestore
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
  // Normaliza el email antes de enviarlo a Firebase Auth
  // para evitar problemas con mayúsculas o espacios
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
  // Delegado a UserService para mantener separación de responsabilidades
  // ----------------------------------------------------------
  Future<List<String>> getUserSports(String uid) async {
    return _userService.getUserSports(uid);
  }

  // ----------------------------------------------------------
  // ACTUALIZAR DEPORTES FAVORITOS DEL USUARIO
  // Delegado a UserService
  // ----------------------------------------------------------
  Future<void> updateFavoriteSports(String uid, List<String> sports) async {
    await _userService.updateFavoriteSports(uid, sports);
  }

  // ----------------------------------------------------------
  // CERRAR SESIÓN
  // Cierra la sesión en Firebase Auth
  // ----------------------------------------------------------
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      // Error no crítico — se registra pero no interrumpe el flujo
      debugPrint("Error al cerrar sesión: $e");
    }
  }

  // ----------------------------------------------------------
  // ELIMINAR CUENTA DE USUARIO
  // Proceso en orden:
  //   1. Elimina todos los posts del usuario en Firestore (batch)
  //   2. Elimina el documento del usuario via UserService
  //   3. Elimina la cuenta de Firebase Auth
  //
  // Requiere login reciente — Firebase lanza requires-recent-login
  // si han pasado más de 5 minutos desde la última autenticación
  // ----------------------------------------------------------
  Future<void> deleteUserAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Paso 1 — Eliminar todos los posts del usuario
      final postsQuery = await _db
          .collection('posts')
          .where('userId', isEqualTo: user.uid)
          .get();

      final batch = _db.batch();
      for (var doc in postsQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Paso 2 — Eliminar datos del usuario en Firestore
      await _userService.deleteUserData(user.uid);

      // Paso 3 — Eliminar la cuenta de Firebase Auth
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
