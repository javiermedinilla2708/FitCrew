// ============================================================
// lib/models/app_notification.dart
// Modelo de datos que representa una notificación en FitCrew.
// Mapea los documentos de la colección 'notifications' en
// Firestore. Las notificaciones se generan automáticamente
// al enviar solicitudes de seguimiento, aceptarlas, apuntarse
// a actividades o crear nuevas actividades.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  // ----------------------------------------------------------
  // CAMPOS
  // ----------------------------------------------------------
  final String id; // ID del documento en Firestore
  final String toUid; // UID del receptor de la notificación
  final String fromUid; // UID del emisor de la notificación
  final String fromName; // Nombre del emisor para mostrar en la UI
  final String type; // Tipo: follow_request | follow_accepted |
  //       activity_joined | new_activity
  final String title; // Título de la notificación
  final String body; // Cuerpo descriptivo del mensaje
  final bool read; // True si el receptor ya la ha leído
  final String?
  activityId; // ID de actividad relacionada (solo en tipos de actividad)
  final DateTime timestamp; // Fecha y hora de creación

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

  // ----------------------------------------------------------
  // FACTORY — deserialización desde DocumentSnapshot Firestore
  // Usa el ID del documento como identificador único.
  // El timestamp usa DateTime.now() como fallback si aún no
  // se ha procesado el FieldValue.serverTimestamp() del servidor.
  // ----------------------------------------------------------
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
