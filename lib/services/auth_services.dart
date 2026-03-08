import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  //Funcion de salida de sesion
  Future<void> signOut() async {
    await _auth.signOut();
  }
}