import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  //Funcion del registro
  Future<User?> registerWithEmail(String email, String password, String name) async {
    UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    User? user = result.user;

    if (user != null) {
      // 1. Actualizamos el perfil de Firebase Auth (Opcional pero recomendado)
      await user.updateDisplayName(name);

      // 2. Guardamos en Firestore (Crucial para tu ProfileScreen)
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': name,
        'email': email,
        'createdAt': DateTime.now(),
        'selectedSports': [], // Se llenará en la siguiente pantalla
      });
    }
    return user;
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