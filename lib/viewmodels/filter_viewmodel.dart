import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcrew/services/user_services.dart'; // Asegúrate de que la ruta sea correcta

class FilterViewModel extends ChangeNotifier {
  // Inyectamos el servicio
  final UserService _userService = UserService();

  // Estado privado
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

  final List<String> _selectedSports = [];
  bool _isLoading = false;

  // Getters para la UI
  List<String> get sports => _sports;
  List<String> get selectedSports => _selectedSports;
  bool get isLoading => _isLoading;
  bool get canFinalize => _selectedSports.length >= 3 && !_isLoading;

  // Lógica de selección
  void toggleSport(String sport) {
    if (_selectedSports.contains(sport)) {
      _selectedSports.remove(sport);
    } else {
      _selectedSports.add(sport);
    }
    notifyListeners();
  }

  // Lógica de guardado usando el UserService
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

  // Iconos: Lógica de presentación delegada al ViewModel
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
