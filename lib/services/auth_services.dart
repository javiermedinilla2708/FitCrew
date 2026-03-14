import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  //Funcion del registro
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      return result.user;
    } catch (e) {
      print("Error en registro: ${e.toString()}");
      return null;
    }
  }

  //Funcion del login
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      return result.user;
    } catch (e) {
      print("Error en login: ${e.toString()}");
      return null;
    }
  }
  // En AuthService
  Future<void> updateFavoriteSports(String uid, List<String> sports) async {
    try {
      await _db.collection('users').doc(uid).update({
        'favoriteSports': sports,
      });
    } catch (e) {
      print("Error al actualizar deportes: $e");
    }
  }

  //Funcion de salida de sesion
  Future<void> signOut() async {
    await _auth.signOut();
  }
}