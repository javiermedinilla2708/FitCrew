import 'package:cloud_firestore/cloud_firestore.dart';

class SportActivity {
  final String id;
  final String title;
  final String sportType;
  final String location;
  final double latitude;
  final double longitude;
  final DateTime date;
  final String organizerId;
  final int totalSlots;
  final int occupiedSlots;
  final String level;
  final String? imageUrl;
  // ✅ AÑADIDO: lista de UIDs para saber quién está apuntado
  final List<String> participants;

  SportActivity({
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
      // ✅ AÑADIDO: deserialización de participants
      participants: List<String>.from(data['participants'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'sportType': sportType,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      // ✅ CORREGIDO: Timestamp en lugar de DateTime nativo
      'date': Timestamp.fromDate(date),
      'organizerId': organizerId,
      'totalSlots': totalSlots,
      'occupiedSlots': occupiedSlots,
      'level': level,
      'imageUrl': imageUrl,
      // ✅ AÑADIDO: serialización de participants
      'participants': participants,
    };
  }

  // ✅ AÑADIDO: copyWith() útil para cuando un usuario se apunta/desapunta
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

  bool get isFull => occupiedSlots >= totalSlots;
  bool isUserJoined(String uid) => participants.contains(uid);
  int get availableSlots => totalSlots - occupiedSlots;
}
