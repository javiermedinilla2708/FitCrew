import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcrew/services/auth_services.dart'; // Ajusta la ruta si es necesario

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => FirebaseAuth.instance.currentUser;

  // --- LÓGICA DE REGISTRO ---
  Future<bool> register(String email, String password, String name) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.registerWithEmail(email, password, name);
      _setLoading(false);
      return true; // Registro exitoso
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false; // Falló el registro
    }
  }

  // --- LÓGICA DE LOGIN ---
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.loginWithEmail(email, password);
      _setLoading(false);
      return true; // Login exitoso
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false; // Falló el login
    }
  }

  // --- CERRAR SESIÓN ---
  Future<void> logout() async {
    await _authService.signOut();
    notifyListeners();
  }

  // --- MÉTODOS PRIVADOS DE APOYO ---
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}