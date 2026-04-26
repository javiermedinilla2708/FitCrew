// ============================================================
// lib/services/notification_service.dart
// Gestiona la creación y lectura de notificaciones en Firestore
// y el envío de push notifications via FCM a través de Railway
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcrew/models/app_notification.dart';
import 'package:fitcrew/models/notification_type.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? _currentUid = FirebaseAuth.instance.currentUser?.uid;

  // URL base de la API Railway
  static const String _baseUrl =
      'https://fitcrew-production-5fe4.up.railway.app';

  // ----------------------------------------------------------
  // ENVIAR PUSH NOTIFICATION VIA RAILWAY
  // Llama al endpoint /notifications/send del backend Python
  // ----------------------------------------------------------
  Future<void> _sendPush({
    required String toUid,
    required String title,
    required String body,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final token = await user.getIdToken();

      final uri = Uri.parse('$_baseUrl/notifications/send').replace(
        queryParameters: {'to_uid': toUid, 'title': title, 'body': body},
      );

      await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    } catch (e) {
      // No bloqueamos el flujo principal si falla la push
    }
  }

  // ----------------------------------------------------------
  // CREAR NOTIFICACIÓN EN FIRESTORE — método base
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
      // No bloqueamos el flujo principal
    }
  }

  // ----------------------------------------------------------
  // NOTIFICAR — solicitud de seguimiento enviada
  // Guarda en Firestore + envía push
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

    // Push notification
    await _sendPush(
      toUid: toUid,
      title: "Nueva solicitud de seguimiento",
      body: "$fromName quiere seguirte",
    );
  }

  // ----------------------------------------------------------
  // NOTIFICAR — solicitud de seguimiento aceptada
  // Guarda en Firestore + envía push
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

    // Push notification
    await _sendPush(
      toUid: toUid,
      title: "Solicitud aceptada",
      body: "$fromName ha aceptado tu solicitud de seguimiento",
    );
  }

  // ----------------------------------------------------------
  // NOTIFICAR — alguien se ha unido a tu actividad
  // Guarda en Firestore + envía push
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

    // Push notification
    await _sendPush(
      toUid: organizerUid,
      title: "Nuevo participante",
      body: "$joinerName se ha unido a \"$activityTitle\"",
    );
  }

  // ----------------------------------------------------------
  // NOTIFICAR — nueva actividad creada
  // Notifica a todos los usuarios con ese deporte favorito
  // Guarda en Firestore + envía push a cada usuario
  // ----------------------------------------------------------
  Future<void> notifyNewActivity({
    required String organizerName,
    required String activityTitle,
    required String activityId,
    required String sportType,
  }) async {
    if (_currentUid == null) return;
    try {
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

        // Push notification a cada usuario con ese deporte
        await _sendPush(
          toUid: user.id,
          title: "Nueva actividad de $sportType",
          body: "$organizerName ha creado \"$activityTitle\"",
        );
      }
    } catch (e) {
      // No se bloquea el flujo principal
    }
  }

  // ----------------------------------------------------------
  // NOTIFICAR — alguien ha dado like a tu post
  // Guarda en Firestore + envia push al autor del post
  // No notifica si el like es del propio autor
  // ----------------------------------------------------------
  Future<void> notifyPostLiked({
    required String postOwnerUid,
    required String likerName,
    required String postId,
  }) async {
    if (_currentUid == null) return;
    if (_currentUid == postOwnerUid) return;

    // Evitar notificaciones duplicadas si ya dio like antes
    try {
      final existing = await _db
          .collection('notifications')
          .where('toUid', isEqualTo: postOwnerUid)
          .where('fromUid', isEqualTo: _currentUid)
          .where('type', isEqualTo: NotificationType.postLiked)
          .where('activityId', isEqualTo: postId)
          .get();

      if (existing.docs.isNotEmpty) return;

      await _createNotification(
        toUid: postOwnerUid,
        fromUid: _currentUid,
        fromName: likerName,
        type: NotificationType.postLiked,
        title: "Nuevo me gusta",
        body: "$likerName ha dado me gusta a tu publicacion",
        activityId: postId,
      );

      await _sendPush(
        toUid: postOwnerUid,
        title: "Nuevo me gusta",
        body: "$likerName ha dado me gusta a tu publicacion",
      );
    } catch (e) {
      // No bloqueamos el flujo principal
    }
  }

  // ----------------------------------------------------------
  // NOTIFICAR — alguien ha comentado en tu post
  // Guarda en Firestore + envia push al autor del post
  // No notifica si el comentario es del propio autor
  // ----------------------------------------------------------
  // ----------------------------------------------------------
  Future<void> notifyPostComment({
    required String postOwnerUid,
    required String commenterName,
    required String postId,
    required String commentText,
  }) async {
    if (_currentUid == null) return;
    if (_currentUid == postOwnerUid) return;

    try {
      final fiveMinutesAgo = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(minutes: 5)),
      );

      final existing = await _db
          .collection('notifications')
          .where('toUid', isEqualTo: postOwnerUid)
          .where('fromUid', isEqualTo: _currentUid)
          .where('type', isEqualTo: NotificationType.postComment)
          .where('activityId', isEqualTo: postId)
          .where('timestamp', isGreaterThan: fiveMinutesAgo)
          .get();

      if (existing.docs.isNotEmpty) return;

      await _createNotification(
        toUid: postOwnerUid,
        fromUid: _currentUid,
        fromName: commenterName,
        type: NotificationType.postComment,
        title: "Nuevo comentario",
        body: "$commenterName ha comentado: \"$commentText\"",
        activityId: postId,
      );

      await _sendPush(
        toUid: postOwnerUid,
        title: "Nuevo comentario",
        body: "$commenterName ha comentado: \"$commentText\"",
      );
    } catch (e) {
      // No bloqueamos el flujo principal
    }
  }

  // ----------------------------------------------------------
  // STREAM — notificaciones en tiempo real
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
