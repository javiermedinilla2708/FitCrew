import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcrew/services/auth_services.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _auth.currentUser;

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

  Future<bool> logout() async {
    try {
      await _authService.signOut();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ✅ Ahora simplemente delega en AuthService, sin lógica propia
  Future<bool> deleteAccount() async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.deleteUserAccount();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
