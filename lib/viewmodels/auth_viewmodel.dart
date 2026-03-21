import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importante para el borrado de posts
import 'package:fitcrew/services/auth_services.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  // Inicializamos las instancias de Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _auth.currentUser;

  // --- LÓGICA DE REGISTRO ---
  Future<bool> register(String email, String password, String name) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.registerWithEmail(email, password, name);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // --- LÓGICA DE LOGIN ---
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.loginWithEmail(email, password);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // --- CERRAR SESIÓN ---
  Future<bool> logout() async {
    try {
      await _authService.signOut();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- BORRAR CUENTA Y PUBLICACIONES ---
  Future<bool> deleteAccount() async {
    _setLoading(true);
    _clearError();
    
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final uid = user.uid;

      // 1. Buscamos todas las publicaciones asociadas al userId
      final postsQuery = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: uid)
          .get();

      // 2. Usamos un Batch para borrar todos los posts de forma atómica
      WriteBatch batch = _firestore.batch();
      for (var doc in postsQuery.docs) {
        batch.delete(doc.reference);
      }

      // 3. Ejecutamos el borrado de los posts
      await batch.commit();

      // 4. Borramos el perfil del usuario en Firestore (colección 'users')
      await _firestore.collection('users').doc(uid).delete();

      // 5. Finalmente, eliminamos el usuario de Firebase Authentication
      await user.delete();

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = _handleFirebaseAuthError(e);
      _setLoading(false);
      return false;
    }
  }

  // --- MÉTODOS PRIVADOS ---
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Manejo de errores específicos (ej. reautenticación necesaria)
  String _handleFirebaseAuthError(dynamic e) {
    if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
      return "Por seguridad, debes haber iniciado sesión recientemente para borrar tu cuenta.";
    }
    return e.toString();
  }
}