// ============================================================
// lib/viewmodels/auth_viewmodel.dart
// ViewModel de autenticación que actúa como intermediario entre
// la UI y AuthService. Gestiona el estado de carga y errores
// siguiendo el patrón MVVM con Provider como sistema de estado.
// ============================================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcrew/services/auth_services.dart';

class AuthViewModel extends ChangeNotifier {
  // ----------------------------------------------------------
  // DEPENDENCIAS
  // ----------------------------------------------------------
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ----------------------------------------------------------
  // ESTADO INTERNO
  // ----------------------------------------------------------
  bool _isLoading = false;
  String? _errorMessage;

  // ----------------------------------------------------------
  // GETTERS PÚBLICOS
  // Exponen el estado interno de forma inmutable a la UI
  // ----------------------------------------------------------
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Devuelve el usuario actualmente autenticado o null si no hay sesión
  User? get currentUser => _auth.currentUser;

  // ----------------------------------------------------------
  // REGISTRO DE USUARIO
  // Delega en AuthService y gestiona el estado de carga.
  // Devuelve true si el registro fue exitoso, false si hubo error.
  // El mensaje de error queda disponible en errorMessage para la UI.
  // ----------------------------------------------------------
  Future<bool> register(String email, String password, String name) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.registerWithEmail(email, password, name);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ----------------------------------------------------------
  // LOGIN DE USUARIO
  // Delega en AuthService y gestiona el estado de carga.
  // Devuelve true si el login fue exitoso, false si hubo error.
  // ----------------------------------------------------------
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.loginWithEmail(email, password);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ----------------------------------------------------------
  // LOGIN CON GOOGLE
  // Devuelve true si el login fue exitoso.
  // isNewUser indica si debe ir a FilterScreen o a HomeScreen.
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> loginWithGoogle() async {
    _setLoading(true);
    _clearError();
    try {
      final result = await _authService.loginWithGoogle();
      return {'success': true, 'isNewUser': result['isNewUser']};
    } catch (e) {
      _errorMessage = e.toString();
      return {'success': false, 'isNewUser': false};
    } finally {
      _setLoading(false);
    }
  }

  // ----------------------------------------------------------
  // CIERRE DE SESIÓN
  // Tras cerrar sesión notifica a los listeners para que la UI
  // reaccione y redirija al usuario a la pantalla de bienvenida.
  // ----------------------------------------------------------
  Future<bool> logout() async {
    try {
      await _authService.signOut();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ----------------------------------------------------------
  // REAUTENTICAR
  // ----------------------------------------------------------
  Future<bool> reauthenticate(String password) async {
    return await _authService.reauthenticate(password);
  }

  // ----------------------------------------------------------
  // ELIMINAR CUENTA
  // Delega completamente en AuthService, que se encarga de:
  //   1. Eliminar los posts del usuario en Firestore
  //   2. Eliminar el documento del usuario
  //   3. Eliminar la cuenta de Firebase Auth
  // Devuelve true si se completó con éxito, false si hubo error.
  // ----------------------------------------------------------
  Future<bool> deleteAccount() async {
    try {
      await _authService.deleteUserAccount();
      return true;
    } catch (e) {
      debugPrint("Error en ViewModel deleteAccount: $e");
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  // ----------------------------------------------------------
  // HELPERS PRIVADOS DE ESTADO
  // ----------------------------------------------------------

  // Activa o desactiva el indicador de carga y notifica a la UI
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Limpia el mensaje de error anterior antes de una nueva operación
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
