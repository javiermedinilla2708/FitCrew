import 'package:flutter/material.dart';

class SportActivity {
  final String id;
  final String title;
  final String sportType;
  final String location;
  final DateTime date;
  final String organizerId;
  final int totalSlots;
  final int occupiedSlots;
  final String level;

  SportActivity({
    required this.id,
    required this.title,
    required this.sportType,
    required this.location,
    required this.date,
    required this.organizerId,
    required this.totalSlots,
    required this.occupiedSlots,
    required this.level,
  });

  // Convierte un JSON/Map de la base de datos a un objeto de clase
  factory SportActivity.fromMap(Map<String, dynamic> data, String id) {
    return SportActivity(
      id: id,
      title: data['title'] ?? '',
      sportType: data['sportType'] ?? 'Otros',
      location: data['location'] ?? '',
      date: data['date'] is DateTime 
          ? data['date'] 
          : DateTime.parse(data['date']), // Maneja string o DateTime
      organizerId: data['organizerId'] ?? '',
      totalSlots: data['totalSlots'] ?? 0,
      occupiedSlots: data['occupiedSlots'] ?? 0,
      level: data['level'] ?? 'Todos',
    );
  }

  // Convierte el objeto a un Map para guardar o editar en la base de datos
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'sportType': sportType,
      'location': location,
      'date': date.toIso8601String(),
      'organizerId': organizerId,
      'totalSlots': totalSlots,
      'occupiedSlots': occupiedSlots,
      'level': level,
    };
  }

  // Método auxiliar para crear una copia modificada 
  SportActivity copyWith({
    String? title,
    String? location,
    int? totalSlots,
    String? level,
  }) {
    return SportActivity(
      id: id,
      title: title ?? this.title,
      sportType: sportType,
      location: location ?? this.location,
      date: date,
      organizerId: organizerId,
      totalSlots: totalSlots ?? this.totalSlots,
      occupiedSlots: occupiedSlots,
      level: level ?? this.level,
    );
  }
}