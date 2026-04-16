// ============================================================
// lib/services/notification_service.dart
// Gestiona la creación y lectura de notificaciones en Firestore
// ============================================================

// ----------------------------------------------------------
// SERVICIO
// ----------------------------------------------------------
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcrew/models/app_notification.dart';
import 'package:fitcrew/models/notification_type.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? _currentUid = FirebaseAuth.instance.currentUser?.uid;

  // ----------------------------------------------------------
  // CREAR NOTIFICACIÓN — método base
  // ----------------------------------------------------------
  Future<void> _createNotification({
    required String toUid,
    required String fromUid,
    required String fromName,
    required String type,
    required String title,
    required String body,
    String? activityId,
  }) async {
    // No enviamos notificaciones a uno mismo
    if (toUid == fromUid) return;

    try {
      await _db.collection('notifications').add({
        'toUid': toUid,
        'fromUid': fromUid,
        'fromName': fromName,
        'type': type,
        'title': title,
        'body': body,
        'read': false,
        'activityId': activityId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // No bloqueamos el flujo principal si falla la notificación
    }
  }

  // ----------------------------------------------------------
  // NOTIFICAR — solicitud de seguimiento enviada
  // ----------------------------------------------------------
  Future<void> notifyFollowRequest({
    required String toUid,
    required String fromName,
  }) async {
    if (_currentUid == null) return;
    await _createNotification(
      toUid: toUid,
      fromUid: _currentUid,
      fromName: fromName,
      type: NotificationType.followRequest,
      title: "Nueva solicitud de seguimiento",
      body: "$fromName quiere seguirte",
    );
  }

  // ----------------------------------------------------------
  // NOTIFICAR — solicitud de seguimiento aceptada
  // ----------------------------------------------------------
  Future<void> notifyFollowAccepted({
    required String toUid,
    required String fromName,
  }) async {
    if (_currentUid == null) return;
    await _createNotification(
      toUid: toUid,
      fromUid: _currentUid,
      fromName: fromName,
      type: NotificationType.followAccepted,
      title: "Solicitud aceptada",
      body: "$fromName ha aceptado tu solicitud de seguimiento",
    );
  }

  // ----------------------------------------------------------
  // NOTIFICAR — alguien se ha unido a tu actividad
  // ----------------------------------------------------------
  Future<void> notifyActivityJoined({
    required String organizerUid,
    required String joinerName,
    required String activityTitle,
    required String activityId,
  }) async {
    if (_currentUid == null) return;
    await _createNotification(
      toUid: organizerUid,
      fromUid: _currentUid,
      fromName: joinerName,
      type: NotificationType.activityJoined,
      title: "Nuevo participante",
      body: "$joinerName se ha unido a \"$activityTitle\"",
      activityId: activityId,
    );
  }

  // ----------------------------------------------------------
  // NOTIFICAR — nueva actividad creada
  // Notifica a todos los usuarios con ese deporte favorito
  // ----------------------------------------------------------
  Future<void> notifyNewActivity({
    required String organizerName,
    required String activityTitle,
    required String activityId,
    required String sportType,
  }) async {
    if (_currentUid == null) return;
    try {
      // Buscamos usuarios con ese deporte favorito
      final users = await _db
          .collection('users')
          .where('favoriteSports', arrayContains: sportType)
          .get();

      for (final user in users.docs) {
        if (user.id == _currentUid) continue;
        await _createNotification(
          toUid: user.id,
          fromUid: _currentUid,
          fromName: organizerName,
          type: NotificationType.newActivity,
          title: "Nueva actividad de $sportType",
          body: "$organizerName ha creado \"$activityTitle\"",
          activityId: activityId,
        );
      }
    } catch (e) {
      // No bloqueamos el flujo principal
    }
  }

  // ----------------------------------------------------------
  // STREAM — notificaciones no leídas en tiempo real
  // ----------------------------------------------------------
  Stream<List<AppNotification>> getNotificationsStream() {
    if (_currentUid == null) return const Stream.empty();
    return _db
        .collection('notifications')
        .where('toUid', isEqualTo: _currentUid)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => AppNotification.fromDoc(doc)).toList(),
        );
  }

  // ----------------------------------------------------------
  // STREAM — contador de notificaciones no leídas
  // ----------------------------------------------------------
  Stream<int> getUnreadCountStream() {
    if (_currentUid == null) return const Stream.empty();
    return _db
        .collection('notifications')
        .where('toUid', isEqualTo: _currentUid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ----------------------------------------------------------
  // MARCAR NOTIFICACIÓN COMO LEÍDA
  // ----------------------------------------------------------
  Future<void> markAsRead(String notificationId) async {
    try {
      await _db.collection('notifications').doc(notificationId).update({
        'read': true,
      });
    } catch (e) {
      // Silencioso
    }
  }

  // ----------------------------------------------------------
  // MARCAR TODAS COMO LEÍDAS
  // ----------------------------------------------------------
  Future<void> markAllAsRead() async {
    if (_currentUid == null) return;
    try {
      final unread = await _db
          .collection('notifications')
          .where('toUid', isEqualTo: _currentUid)
          .where('read', isEqualTo: false)
          .get();

      final batch = _db.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      // Silencioso
    }
  }

  // ----------------------------------------------------------
  // ELIMINAR NOTIFICACIÓN
  // ----------------------------------------------------------
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _db.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      // Silencioso
    }
  }
}
