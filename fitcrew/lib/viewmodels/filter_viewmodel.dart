// ============================================================
// lib/viewmodels/filter_viewmodel.dart
// ViewModel del proceso de onboarding — selección de deportes
// favoritos. Gestiona la lista completa de deportes disponibles,
// los deportes seleccionados por el usuario y su persistencia
// en Firestore via UserService.
// ============================================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcrew/services/user_services.dart';

class FilterViewModel extends ChangeNotifier {
  // ----------------------------------------------------------
  // DEPENDENCIAS
  // ----------------------------------------------------------
  final UserService _userService = UserService();

  // ----------------------------------------------------------
  // CATÁLOGO COMPLETO DE DEPORTES DISPONIBLES
  // Lista estática con todos los deportes que el usuario
  // puede seleccionar como favoritos durante el onboarding
  // ----------------------------------------------------------
  final List<String> _sports = [
    "Padel",
    "Tenis",
    "Bádminton",
    "Ping Pong",
    "Fútbol",
    "Basket",
    "Voleibol",
    "Balonmano",
    "Rugby",
    "Running",
    "Ciclismo",
    "Natación",
    "Triatlón",
    "Patinaje",
    "Yoga",
    "Crossfit",
    "Gimnasio",
    "Calistenia",
    "Pilates",
    "Boxeo",
    "Judo",
    "Karate",
    "MMA",
    "Senderismo",
    "Escalada",
    "Surf",
    "Golf",
  ];

  // ----------------------------------------------------------
  // ESTADO INTERNO
  // ----------------------------------------------------------
  final List<String> _selectedSports = [];
  bool _isLoading = false;

  // ----------------------------------------------------------
  // GETTERS PÚBLICOS
  // ----------------------------------------------------------
  List<String> get sports => _sports;
  List<String> get selectedSports => _selectedSports;
  bool get isLoading => _isLoading;

  // El usuario debe seleccionar al menos 3 deportes para continuar
  bool get canFinalize => _selectedSports.length >= 3 && !_isLoading;

  // ----------------------------------------------------------
  // TOGGLE DE SELECCIÓN DE DEPORTE
  // Si el deporte ya está seleccionado lo deselecciona,
  // si no está seleccionado lo añade a la lista
  // ----------------------------------------------------------
  void toggleSport(String sport) {
    if (_selectedSports.contains(sport)) {
      _selectedSports.remove(sport);
    } else {
      _selectedSports.add(sport);
    }
    notifyListeners();
  }

  // ----------------------------------------------------------
  // GUARDAR DEPORTES FAVORITOS
  // Persiste la selección en Firestore y marca el setup como
  // completado para que la app no vuelva a mostrar el onboarding.
  // Devuelve true si se guardó correctamente, false si falló.
  // ----------------------------------------------------------
  Future<bool> saveUserSports() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _userService.updateFavoriteSports(user.uid, _selectedSports);
        await _userService.updateSetupComplete(user.uid);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error en FilterViewModel al guardar: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ----------------------------------------------------------
  // OBTENER ICONO SEGÚN EL DEPORTE
  // Lógica de presentación delegada al ViewModel para mantener
  // las pantallas limpias de lógica condicional.
  // Devuelve un icono de Material Design acorde al deporte.
  // ----------------------------------------------------------
  IconData getSportIcon(String sportType) {
    switch (sportType.toLowerCase()) {
      case 'padel':
      case 'tenis':
        return Icons.sports_tennis;
      case 'bádminton':
        return Icons.wb_iridescent_rounded;
      case 'ping pong':
        return Icons.table_restaurant_rounded;
      case 'fútbol':
      case 'balonmano':
        return Icons.sports_soccer;
      case 'basket':
        return Icons.sports_basketball;
      case 'voleibol':
        return Icons.sports_volleyball;
      case 'rugby':
        return Icons.sports_rugby;
      case 'running':
        return Icons.directions_run;
      case 'ciclismo':
        return Icons.directions_bike;
      case 'natación':
        return Icons.pool;
      case 'triatlón':
        return Icons.directions_run_rounded;
      case 'patinaje':
        return Icons.ice_skating;
      case 'yoga':
      case 'pilates':
        return Icons.self_improvement;
      case 'crossfit':
      case 'gimnasio':
      case 'calistenia':
        return Icons.fitness_center;
      case 'boxeo':
      case 'mma':
        return Icons.sports_mma;
      case 'judo':
      case 'karate':
        return Icons.front_hand;
      case 'senderismo':
        return Icons.terrain;
      case 'escalada':
        return Icons.landscape;
      case 'surf':
        return Icons.surfing;
      case 'golf':
        return Icons.sports_golf;
      default:
        return Icons.bolt;
    }
  }
}
