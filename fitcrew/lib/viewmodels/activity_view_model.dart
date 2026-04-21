// ============================================================
// activity_view_model.dart
// ViewModel que gestiona el estado de las actividades deportivas
// ============================================================

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitcrew/services/activity_service.dart';
import 'package:fitcrew/services/notification_service.dart';
import 'package:fitcrew/models/sport_activity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class ActivityViewModel extends ChangeNotifier {
  // ----------------------------------------------------------
  // DEPENDENCIAS
  // ----------------------------------------------------------
  final ActivityService _activityService = ActivityService();
  final NotificationService _notifService = NotificationService();

  StreamSubscription<List<SportActivity>>? _subscription;

  // ----------------------------------------------------------
  // ESTADO INTERNO
  // ----------------------------------------------------------
  List<SportActivity> _activities = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  // ----------------------------------------------------------
  // GETTERS PÚBLICOS
  // ----------------------------------------------------------
  List<SportActivity> get activities => _activities;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ----------------------------------------------------------
  // NOTIFICACIÓN SEGURA
  // ----------------------------------------------------------
  void _notify() {
    if (_disposed) return;

    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  // ----------------------------------------------------------
  // ESCUCHAR ACTIVIDADES EN TIEMPO REAL
  // ----------------------------------------------------------
  void listenToActivities() {
    _subscription?.cancel();

    _isLoading = true;
    _notify();

    _subscription = _activityService.getActivitiesStream().listen(
      (newList) {
        _activities = newList;
        _errorMessage = null;
        _isLoading = false;
        _notify();
      },
      onError: (error) {
        _errorMessage = error.toString();
        _isLoading = false;
        _notify();
      },
    );
  }

  // ----------------------------------------------------------
  // CREAR ACTIVIDAD
  // Notifica a usuarios con ese deporte favorito
  // ----------------------------------------------------------
  Future<void> addActivity(SportActivity activity) async {
    try {
      _isLoading = true;
      _notify();

      // Creamos la actividad y obtenemos el ID generado
      final activityId = await _activityService.createActivity(activity);
      _errorMessage = null;

      // Obtenemos el nombre del organizador
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid != null && activityId != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUid)
            .get();
        final organizerName = userDoc.data()?['name'] ?? 'Usuario';

        // Notificar a usuarios con ese deporte favorito
        await _notifService.notifyNewActivity(
          organizerName: organizerName,
          activityTitle: activity.title,
          activityId: activityId,
          sportType: activity.sportType,
        );
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  Future<bool> deleteActivity(String activityId) async {
    try {
      await _activityService.deleteActivity(activityId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _notify();
      return false;
    }
  }

  // ----------------------------------------------------------
  // APUNTARSE A UNA ACTIVIDAD
  // Notifica al organizador
  // ----------------------------------------------------------
  Future<bool> joinActivity(String activityId) async {
    try {
      await _activityService.joinActivity(activityId);

      // Obtenemos los datos necesarios para la notificación
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid != null) {
        // Nombre del usuario que se apunta
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUid)
            .get();
        final joinerName = userDoc.data()?['name'] ?? 'Usuario';

        // Datos de la actividad
        final activity = _activities.firstWhere(
          (a) => a.id == activityId,
          orElse: () => throw Exception('Actividad no encontrada'),
        );

        // Notificar al organizador si no es el mismo usuario
        if (activity.organizerId != currentUid) {
          await _notifService.notifyActivityJoined(
            organizerUid: activity.organizerId,
            joinerName: joinerName,
            activityTitle: activity.title,
            activityId: activityId,
          );
        }
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _notify();
      return false;
    }
  }

  // ----------------------------------------------------------
  // DESAPUNTARSE DE UNA ACTIVIDAD
  // ----------------------------------------------------------
  Future<bool> leaveActivity(String activityId) async {
    try {
      return await _activityService.leaveActivity(activityId);
    } catch (e) {
      return false;
    }
  }

  // ----------------------------------------------------------
  // FILTRADO POR DEPORTE
  // ----------------------------------------------------------
  List<SportActivity> getActivitiesBySport(String sport) {
    if (sport == 'Todos') return _activities;
    return _activities
        .where((activity) => activity.sportType == sport)
        .toList();
  }

  // ----------------------------------------------------------
  // DATOS DE PRUEBA
  // ----------------------------------------------------------
  void loadMockData() {
    _activities = [
      SportActivity(
        id: '1',
        title: 'Padel 2x2 Mañana',
        sportType: 'Padel',
        location: 'Club de Tenis',
        latitude: 40.4167,
        longitude: -3.7037,
        date: DateTime.now().add(const Duration(days: 1)),
        organizerId: 'user_01',
        totalSlots: 4,
        occupiedSlots: 3,
        level: 'Medio',
        imageUrl: null,
      ),
      SportActivity(
        id: '2',
        title: 'Corrida Mañanera',
        sportType: 'Running',
        location: 'Parque del Retiro',
        latitude: 40.4125,
        longitude: -3.6785,
        date: DateTime.now().add(const Duration(days: 1, hours: 10)),
        organizerId: 'user_02',
        totalSlots: 10,
        occupiedSlots: 6,
        level: 'Todos',
        imageUrl: null,
      ),
    ];
    _errorMessage = null;
    notifyListeners();
  }

  // ----------------------------------------------------------
  // DISPOSE
  // ----------------------------------------------------------
  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
