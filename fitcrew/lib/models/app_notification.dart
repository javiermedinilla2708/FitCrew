import 'package:cloud_firestore/cloud_firestore.dart';

// ----------------------------------------------------------
// MODELO DE NOTIFICACIÓN
// ----------------------------------------------------------
class AppNotification {
  final String id;
  final String toUid;
  final String fromUid;
  final String fromName;
  final String type;
  final String title;
  final String body;
  final bool read;
  final String? activityId;
  final DateTime timestamp;

  const AppNotification({
    required this.id,
    required this.toUid,
    required this.fromUid,
    required this.fromName,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    this.activityId,
    required this.timestamp,
  });

  factory AppNotification.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      toUid: data['toUid'] ?? '',
      fromUid: data['fromUid'] ?? '',
      fromName: data['fromName'] ?? 'Usuario',
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      read: data['read'] ?? false,
      activityId: data['activityId'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
