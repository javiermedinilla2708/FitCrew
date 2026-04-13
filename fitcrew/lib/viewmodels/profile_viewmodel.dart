import 'package:flutter/material.dart';
import 'package:fitcrew/services/auth_services.dart';

class ProfileViewModel extends ChangeNotifier {
  // ✅ Solo necesita AuthService, nada de Firebase directo
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> signOut() async {
    await _authService.signOut();
  }

  // ✅ Delega completamente en AuthService
  Future<void> deleteAccount() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.deleteUserAccount();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
