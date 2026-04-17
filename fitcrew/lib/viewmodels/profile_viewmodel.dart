// ============================================================
// lib/viewmodels/profile_viewmodel.dart
// ViewModel del perfil de usuario. Actúa como capa intermedia
// entre ProfileScreen y AuthService, gestionando el estado de
// carga durante operaciones como cierre de sesión y eliminación
// de cuenta. Sigue el principio de responsabilidad única:
// no contiene lógica de negocio propia, solo delega en AuthService.
// ============================================================

import 'package:flutter/material.dart';
import 'package:fitcrew/services/auth_services.dart';

class ProfileViewModel extends ChangeNotifier {
  // ----------------------------------------------------------
  // DEPENDENCIAS
  // ----------------------------------------------------------
  final AuthService _authService = AuthService();

  // ----------------------------------------------------------
  // ESTADO INTERNO
  // ----------------------------------------------------------
  bool _isLoading = false;

  // ----------------------------------------------------------
  // GETTERS PÚBLICOS
  // ----------------------------------------------------------
  bool get isLoading => _isLoading;

  // ----------------------------------------------------------
  // CERRAR SESIÓN
  // Delega directamente en AuthService sin gestión de estado
  // de carga ya que es una operación instantánea
  // ----------------------------------------------------------
  Future<void> signOut() async {
    await _authService.signOut();
  }

  // ----------------------------------------------------------
  // ELIMINAR CUENTA
  // Gestiona el estado de carga durante el proceso de borrado.
  // Relanza la excepción (rethrow) para que ProfileScreen
  // pueda mostrar el mensaje de error apropiado al usuario.
  // El proceso completo en AuthService incluye:
  //   1. Borrar posts del usuario en Firestore
  //   2. Borrar documento del usuario
  //   3. Borrar cuenta de Firebase Auth
  // ----------------------------------------------------------
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
