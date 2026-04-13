import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fitcrew/services/api_service.dart';

// ============================================================
// StatsViewModel
// Gestiona el estado de estadísticas y ranking
// obtenidos desde la API REST de Python
// ============================================================

class StatsViewModel extends ChangeNotifier {
  // ----------------------------------------------------------
  // DEPENDENCIAS
  // ----------------------------------------------------------
  final ApiService _apiService = ApiService();

  // ----------------------------------------------------------
  // ESTADO — Estadísticas de usuario
  // ----------------------------------------------------------
  UserStats? _userStats;
  bool _isLoadingStats = false;
  String? _statsError;

  UserStats? get userStats => _userStats;
  bool get isLoadingStats => _isLoadingStats;
  String? get statsError => _statsError;

  // ----------------------------------------------------------
  // ESTADO — Ranking global
  // ----------------------------------------------------------
  List<RankingEntry> _globalRanking = [];
  bool _isLoadingRanking = false;
  String? _rankingError;

  List<RankingEntry> get globalRanking => _globalRanking;
  bool get isLoadingRanking => _isLoadingRanking;
  String? get rankingError => _rankingError;

  // ----------------------------------------------------------
  // ESTADO — Recomendaciones
  // ----------------------------------------------------------
  List<ActivityRecommendation> _recommendations = [];
  bool _isLoadingRecommendations = false;

  List<ActivityRecommendation> get recommendations => _recommendations;
  bool get isLoadingRecommendations => _isLoadingRecommendations;

  // ----------------------------------------------------------
  // CARGAR ESTADÍSTICAS DEL USUARIO ACTUAL
  // ----------------------------------------------------------
  Future<void> loadUserStats() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _isLoadingStats = true;
    _statsError = null;
    notifyListeners();

    try {
      _userStats = await _apiService.getUserStats(uid);
      if (_userStats == null) {
        _statsError = "No se pudieron cargar las estadísticas";
      }
    } catch (e) {
      _statsError = e.toString();
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  // ----------------------------------------------------------
  // CARGAR RANKING GLOBAL
  // ----------------------------------------------------------
  Future<void> loadGlobalRanking() async {
    _isLoadingRanking = true;
    _rankingError = null;
    notifyListeners();

    try {
      _globalRanking = await _apiService.getGlobalRanking();
      if (_globalRanking.isEmpty) {
        _rankingError = "No hay datos de ranking aún";
      }
    } catch (e) {
      _rankingError = e.toString();
    } finally {
      _isLoadingRanking = false;
      notifyListeners();
    }
  }

  // ----------------------------------------------------------
  // CARGAR RANKING POR DEPORTE
  // ----------------------------------------------------------
  Future<void> loadSportRanking(String sport) async {
    _isLoadingRanking = true;
    _rankingError = null;
    notifyListeners();

    try {
      _globalRanking = await _apiService.getSportRanking(sport);
      if (_globalRanking.isEmpty) {
        _rankingError = "No hay datos para este deporte aún";
      }
    } catch (e) {
      _rankingError = e.toString();
    } finally {
      _isLoadingRanking = false;
      notifyListeners();
    }
  }

  // ----------------------------------------------------------
  // CARGAR RECOMENDACIONES
  // ----------------------------------------------------------
  Future<void> loadRecommendations() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _isLoadingRecommendations = true;
    notifyListeners();

    try {
      _recommendations = await _apiService.getRecommendations(uid);
    } catch (e) {
      _recommendations = [];
    } finally {
      _isLoadingRecommendations = false;
      notifyListeners();
    }
  }

  // ----------------------------------------------------------
  // CARGAR TODO A LA VEZ
  // ----------------------------------------------------------
  Future<void> loadAll() async {
    await Future.wait([
      loadUserStats(),
      loadGlobalRanking(),
      loadRecommendations(),
    ]);
  }
}
