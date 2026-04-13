import 'package:flutter/material.dart';

// ============================================================
// AppConstants
// Constantes globales y utilidades de la aplicación
// ============================================================

class AppConstants {
  // ----------------------------------------------------------
  // LISTADO DE DEPORTES DISPONIBLES
  // ----------------------------------------------------------
  static const List<String> availableSports = [
    // Deportes de Raqueta
    "Padel",
    "Tenis",
    "Bádminton",
    "Ping Pong",

    // Deportes de Equipo
    "Fútbol",
    "Basket",
    "Voleibol",
    "Balonmano",
    "Rugby",

    // Resistencia y Cardio
    "Running",
    "Ciclismo",
    "Natación",
    "Triatlón",
    "Patinaje",

    // Entrenamiento y Fuerza
    "Yoga",
    "Crossfit",
    "Gimnasio",
    "Calistenia",
    "Pilates",

    // Deportes de Combate
    "Boxeo",
    "Judo",
    "Karate",
    "MMA",

    // Aire Libre y Otros
    "Senderismo",
    "Escalada",
    "Surf",
    "Golf",
  ];

  // ----------------------------------------------------------
  // NIVELES DE HABILIDAD
  // ----------------------------------------------------------
  static const List<String> skillLevels = [
    "Principiante",
    "Intermedio",
    "Avanzado",
    "Profesional",
  ];

  // ----------------------------------------------------------
  // ICONOS DE DEPORTES
  // Uso: AppConstants.getSportIcon("Padel")
  // ----------------------------------------------------------
  static IconData getSportIcon(String sportType) {
    switch (sportType.toLowerCase()) {
      // Deportes de Raqueta
      case 'padel':
      case 'tenis':
        return Icons.sports_tennis;
      case 'bádminton':
        return Icons.wb_iridescent_rounded;
      case 'ping pong':
        return Icons.table_restaurant_rounded;

      // Deportes de Equipo
      case 'fútbol':
      case 'balonmano':
        return Icons.sports_soccer;
      case 'basket':
        return Icons.sports_basketball;
      case 'voleibol':
        return Icons.sports_volleyball;
      case 'rugby':
        return Icons.sports_rugby;

      // Resistencia y Cardio
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

      // Entrenamiento y Fuerza
      case 'yoga':
      case 'pilates':
        return Icons.self_improvement;
      case 'crossfit':
      case 'gimnasio':
      case 'calistenia':
        return Icons.fitness_center;

      // Deportes de Combate
      case 'boxeo':
      case 'mma':
        return Icons.sports_mma;
      case 'judo':
      case 'karate':
        return Icons.front_hand;

      // Aire Libre y Otros
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
