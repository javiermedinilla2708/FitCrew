// ============================================================
// activity_view_model.dart
// ViewModel que gestiona el estado de las actividades deportivas
// ============================================================

import 'dart:async';
import 'package:fitcrew/services/activity_service.dart';
import 'package:fitcrew/models/sport_activity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class ActivityViewModel extends ChangeNotifier {
  // ----------------------------------------------------------
  // DEPENDENCIAS
  // ----------------------------------------------------------
  final ActivityService _activityService = ActivityService();

  // Suscripción al stream de Firestore (necesaria para cancelarla en dispose)
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
  // ----------------------------------------------------------
  Future<void> addActivity(SportActivity activity) async {
    try {
      _isLoading = true;
      _notify();

      await _activityService.createActivity(activity);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  // ----------------------------------------------------------
  // APUNTARSE A UNA ACTIVIDAD
  // ----------------------------------------------------------
  Future<bool> joinActivity(String activityId) async {
    try {
      await _activityService.joinActivity(activityId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _notify();
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
  // DATOS DE PRUEBA (desarrollo / testing)
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
  // DISPOSE — limpieza de recursos
  // ----------------------------------------------------------
  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
