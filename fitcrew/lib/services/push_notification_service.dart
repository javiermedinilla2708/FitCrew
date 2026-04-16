// ============================================================
// lib/services/push_notification_service.dart
// Gestiona FCM: tokens, permisos y notificaciones locales
// ============================================================

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await PushNotificationService.showLocalNotification(message);
}

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'fitcrew_channel',
    'FitCrew Notificaciones',
    description: 'Notificaciones de actividades y seguimiento',
    importance: Importance.high,
    playSound: true,
  );

  // ----------------------------------------------------------
  // INICIALIZAR
  // ----------------------------------------------------------
  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    debugPrint('FCM: Permiso ${settings.authorizationStatus}');

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _localNotif
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_channel);

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotif.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('FCM: Notificación pulsada: ${details.payload}');
      },
    );

    await _saveToken();
    _messaging.onTokenRefresh.listen(_updateToken);

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('FCM: Mensaje en foreground: ${message.messageId}');
      showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('FCM: App abierta desde notificación: ${message.data}');
    });
  }

  // ----------------------------------------------------------
  // GUARDAR TOKEN FCM EN FIRESTORE
  // ----------------------------------------------------------
  static Future<void> _saveToken() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final token = await _messaging.getToken();
      if (token == null) return;

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': token,
      });

      debugPrint('FCM: Token guardado: ${token.substring(0, 20)}...');
    } catch (e) {
      debugPrint('FCM: Error guardando token: $e');
    }
  }

  // ----------------------------------------------------------
  // ACTUALIZAR TOKEN
  // ----------------------------------------------------------
  static Future<void> _updateToken(String token) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': token,
      });

      debugPrint('FCM: Token actualizado');
    } catch (e) {
      debugPrint('FCM: Error actualizando token: $e');
    }
  }

  // ----------------------------------------------------------
  // MOSTRAR NOTIFICACIÓN LOCAL
  // ----------------------------------------------------------
  static Future<void> showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotif.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  // ----------------------------------------------------------
  // OBTENER TOKEN
  // ----------------------------------------------------------
  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  // ----------------------------------------------------------
  // LIMPIAR TOKEN AL CERRAR SESIÓN
  // ----------------------------------------------------------
  static Future<void> clearToken() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': FieldValue.delete(),
      });

      await _messaging.deleteToken();
      debugPrint('FCM: Token eliminado');
    } catch (e) {
      debugPrint('FCM: Error eliminando token: $e');
    }
  }
}
