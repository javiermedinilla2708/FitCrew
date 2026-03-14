import 'package:cloud_firestore/cloud_firestore.dart';

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
  final String? imageUrl; 

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
    this.imageUrl,
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
      date: parsedDate,
      organizerId: data['organizerId'] ?? '',
      totalSlots: data['totalSlots'] ?? 0,
      occupiedSlots: data['occupiedSlots'] ?? 0,
      level: data['level'] ?? 'Todos',
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'sportType': sportType,
      'location': location,
      'date': date, 
      'organizerId': organizerId,
      'totalSlots': totalSlots,
      'occupiedSlots': occupiedSlots,
      'level': level,
      'imageUrl': imageUrl,
    };
  }
}