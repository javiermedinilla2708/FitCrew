import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- REGISTRO ---
  Future<User?> registerWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        await user.updateDisplayName(name);

        // Guardamos el documento inicial en Firestore
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': normalizedEmail,
          'createdAt': FieldValue.serverTimestamp(),
          'favoriteSports': [],
          'profilePic': null,
          'bio': "",
        });
      }
      return user;
    } on FirebaseAuthException catch (e) {
      // Mapeo de errores para que la UI reciba mensajes legibles
      String errorMessage = "Ocurrió un error inesperado";
      if (e.code == 'email-already-in-use') {
        errorMessage = "Este correo electrónico ya está registrado.";
      } else if (e.code == 'weak-password') {
        errorMessage = "La contraseña es demasiado débil.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "El formato del correo electrónico no es válido.";
      }
      throw errorMessage;
    } catch (e) {
      throw "Error general: ${e.toString()}";
    }
  }

  // --- LOGIN ---
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Error al iniciar sesión";
      if (e.code == 'user-not-found') {
        errorMessage = "No existe ningún usuario con este correo.";
      } else if (e.code == 'wrong-password') {
        errorMessage = "La contraseña es incorrecta.";
      } else if (e.code == 'user-disabled') {
        errorMessage = "Esta cuenta ha sido deshabilitada.";
      } else if (e.code == 'invalid-credential') {
        errorMessage = "Credenciales incorrectas o expiradas.";
      }
      throw errorMessage;
    } catch (e) {
      throw "Error inesperado al intentar entrar.";
    }
  }

  // --- OBTENER DEPORTES DEL USUARIO ---
  Future<List<String>> getUserSports(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Casteo seguro de la lista
        return List<String>.from(data['favoriteSports'] ?? []);
      }
      return [];
    } catch (e) {
      print("Error al obtener deportes: $e");
      return [];
    }
  }

  // --- ACTUALIZAR DEPORTES FAVORITOS ---
  Future<void> updateFavoriteSports(String uid, List<String> sports) async {
    try {
      await _db.collection('users').doc(uid).update({'favoriteSports': sports});
    } catch (e) {
      print("Error al actualizar deportes: $e");
      throw "No se pudieron guardar tus deportes favoritos.";
    }
  }

  // --- CERRAR SESIÓN ---
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("Error al cerrar sesión: $e");
    }
  }

  // --- BORRAR CUENTA ---
  Future<void> deleteUserAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // 1. Borramos datos en Firestore primero
        await _db.collection('users').doc(user.uid).delete();
        // 2. Borramos la cuenta de Auth
        await user.delete();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw "Por seguridad, debes haber iniciado sesión recientemente para borrar tu cuenta.";
      }
      rethrow;
    } catch (e) {
      throw "No se pudo eliminar la cuenta.";
    }
  }
}
