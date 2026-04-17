// ============================================================
// lib/models/sport_activity.dart
// Modelo de datos que representa una actividad deportiva
// publicada en el mapa. Mapea el documento de la colección
// 'activities' en Firestore e incluye lógica de negocio básica
// como comprobar si está llena o si un usuario está apuntado.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class SportActivity {
  // ----------------------------------------------------------
  // CAMPOS
  // ----------------------------------------------------------
  final String id; // ID del documento en Firestore
  final String title; // Nombre del evento
  final String sportType; // Tipo de deporte (ej: "Pádel")
  final String location; // Nombre textual de la ubicación
  final double latitude; // Coordenada geográfica latitud
  final double longitude; // Coordenada geográfica longitud
  final DateTime date; // Fecha y hora del evento
  final String organizerId; // UID del usuario organizador
  final int totalSlots; // Plazas totales del evento
  final int occupiedSlots; // Plazas actualmente ocupadas
  final String level; // Nivel requerido (ej: "Principiante")
  final String? imageUrl; // Imagen opcional del evento
  final List<String> participants; // Lista de UIDs de participantes apuntados

  const SportActivity({
    required this.id,
    required this.title,
    required this.sportType,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.date,
    required this.organizerId,
    required this.totalSlots,
    required this.occupiedSlots,
    required this.level,
    this.imageUrl,
    this.participants = const [],
  });

  // ----------------------------------------------------------
  // FACTORY — deserialización desde Firestore
  // Maneja tres posibles formatos del campo date:
  //   - Timestamp de Firestore (formato habitual)
  //   - String ISO 8601 (formato alternativo)
  //   - Ausente o nulo (usa DateTime.now() como fallback)
  // ----------------------------------------------------------
  factory SportActivity.fromMap(Map<String, dynamic> data, String id) {
    DateTime parsedDate;
    if (data['date'] is Timestamp) {
      parsedDate = (data['date'] as Timestamp).toDate();
    } else if (data['date'] is String) {
      parsedDate = DateTime.parse(data['date']);
    } else {
      parsedDate = DateTime.now();
    }

    return SportActivity(
      id: id,
      title: data['title'] ?? '',
      sportType: data['sportType'] ?? 'Otros',
      location: data['location'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      date: parsedDate,
      organizerId: data['organizerId'] ?? '',
      totalSlots: data['totalSlots'] ?? 0,
      occupiedSlots: data['occupiedSlots'] ?? 0,
      level: data['level'] ?? 'Todos',
      imageUrl: data['imageUrl'],
      participants: List<String>.from(data['participants'] ?? []),
    );
  }

  // ----------------------------------------------------------
  // SERIALIZACIÓN — conversión a Map para Firestore
  // Nota: el campo 'id' no se incluye porque Firestore lo
  // gestiona como ID del documento, no como campo interno.
  // ----------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'sportType': sportType,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'date': Timestamp.fromDate(date),
      'organizerId': organizerId,
      'totalSlots': totalSlots,
      'occupiedSlots': occupiedSlots,
      'level': level,
      'imageUrl': imageUrl,
      'participants': participants,
    };
  }

  // ----------------------------------------------------------
  // COPY WITH — copia inmutable con campos modificados
  // ----------------------------------------------------------
  SportActivity copyWith({
    String? id,
    String? title,
    String? sportType,
    String? location,
    double? latitude,
    double? longitude,
    DateTime? date,
    String? organizerId,
    int? totalSlots,
    int? occupiedSlots,
    String? level,
    String? imageUrl,
    List<String>? participants,
  }) {
    return SportActivity(
      id: id ?? this.id,
      title: title ?? this.title,
      sportType: sportType ?? this.sportType,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      date: date ?? this.date,
      organizerId: organizerId ?? this.organizerId,
      totalSlots: totalSlots ?? this.totalSlots,
      occupiedSlots: occupiedSlots ?? this.occupiedSlots,
      level: level ?? this.level,
      imageUrl: imageUrl ?? this.imageUrl,
      participants: participants ?? this.participants,
    );
  }

  // ----------------------------------------------------------
  // GETTERS DE NEGOCIO
  // Encapsulan lógica derivada del estado del modelo
  // ----------------------------------------------------------

  // True si no quedan plazas disponibles
  bool get isFull => occupiedSlots >= totalSlots;

  // True si el usuario con el uid dado está apuntado
  bool isUserJoined(String uid) => participants.contains(uid);

  // Número de plazas todavía disponibles
  int get availableSlots => totalSlots - occupiedSlots;
}
