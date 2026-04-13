import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcrew/services/user_services.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final UserService _userService = UserService();

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

  Future<List<String>> getUserSports(String uid) async {
    return _userService.getUserSports(uid);
  }

  Future<void> updateFavoriteSports(String uid, List<String> sports) async {
    await _userService.updateFavoriteSports(uid, sports);
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("Error al cerrar sesión: $e");
    }
  }

  Future<void> deleteUserAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final postsQuery = await _db
          .collection('posts')
          .where('userId', isEqualTo: user.uid)
          .get();

      final batch = _db.batch();
      for (var doc in postsQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      await _userService.deleteUserData(user.uid);

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
