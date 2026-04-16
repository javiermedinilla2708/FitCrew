import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ============================================================
// ApiService
// Servicio que gestiona las llamadas HTTP a la API REST
// de FitCrew (FastAPI en Python)
// ============================================================

class ApiService {
  // ----------------------------------------------------------
  // URL BASE
  // ----------------------------------------------------------
  // URL pública de Railway
  static const String _baseUrl =
      'https://fitcrew-production-5fe4.up.railway.app';

  // ----------------------------------------------------------
  // HELPER: Obtener token de Firebase Auth
  // ----------------------------------------------------------
  Future<String?> _getToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      return await user.getIdToken();
    } catch (e) {
      return null;
    }
  }

  // ----------------------------------------------------------
  // HELPER: Cabeceras con token de autenticación
  // ----------------------------------------------------------
  Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ----------------------------------------------------------
  // GET /stats/user/{uid}
  // ----------------------------------------------------------
  Future<UserStats?> getUserStats(String uid) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/stats/user/$uid'),
        headers: await _headers(),
      );
      debugPrint("FITCREW API: getUserStats status=${response.statusCode}");
      debugPrint("FITCREW API: body=${response.body}");

      if (response.statusCode == 200) {
        return UserStats.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint("FITCREW API: Error getUserStats: $e");
      return null;
    }
  }

  // ----------------------------------------------------------
  // GET /stats/activity/{activityId}
  // ----------------------------------------------------------
  Future<ActivityStats?> getActivityStats(String activityId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/stats/activity/$activityId'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        return ActivityStats.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ----------------------------------------------------------
  // GET /stats/recommendations/{uid}
  // ----------------------------------------------------------
  Future<List<ActivityRecommendation>> getRecommendations(String uid) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/stats/recommendations/$uid'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((item) => ActivityRecommendation.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ----------------------------------------------------------
  // GET /ranking/global
  // ----------------------------------------------------------
  Future<List<RankingEntry>> getGlobalRanking() async {
    try {
      final headers = await _headers();
      final token = headers['Authorization'];
      print('Token: ${token?.substring(0, 20)}...'); // Ver si hay token

      final uri = Uri.parse('$_baseUrl/ranking/global');
      print('Llamando a: $uri'); // Ver la URL

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 30)); // Timeout de 30 segundos

      print('Status code: ${response.statusCode}');
      print('Body: ${response.body.substring(0, 100)}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => RankingEntry.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error en getGlobalRanking: $e'); // Ver el error exacto
      return [];
    }
  }

  // ----------------------------------------------------------
  // GET /ranking/sport/{sport}
  // ----------------------------------------------------------
  Future<List<RankingEntry>> getSportRanking(String sport) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/ranking/sport/$sport'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => RankingEntry.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

// ============================================================
// MODELOS DART
// ============================================================

// ----------------------------------------------------------
// UserStats
// ----------------------------------------------------------
class UserStats {
  final String uid;
  final String name;
  final int totalPosts;
  final int totalActivitiesJoined;
  final int totalActivitiesOrganized;
  final String? favoriteSport;
  final int currentStreakDays;

  UserStats({
    required this.uid,
    required this.name,
    required this.totalPosts,
    required this.totalActivitiesJoined,
    required this.totalActivitiesOrganized,
    this.favoriteSport,
    required this.currentStreakDays,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      totalPosts: json['total_posts'] ?? 0,
      totalActivitiesJoined: json['total_activities_joined'] ?? 0,
      totalActivitiesOrganized: json['total_activities_organized'] ?? 0,
      favoriteSport: json['favorite_sport'],
      currentStreakDays: json['current_streak_days'] ?? 0,
    );
  }
}

// ----------------------------------------------------------
// ActivityStats
// ----------------------------------------------------------
class ActivityStats {
  final String activityId;
  final String title;
  final String sportType;
  final int totalSlots;
  final int occupiedSlots;
  final double occupancyRate;
  final bool isFull;

  ActivityStats({
    required this.activityId,
    required this.title,
    required this.sportType,
    required this.totalSlots,
    required this.occupiedSlots,
    required this.occupancyRate,
    required this.isFull,
  });

  factory ActivityStats.fromJson(Map<String, dynamic> json) {
    return ActivityStats(
      activityId: json['activity_id'] ?? '',
      title: json['title'] ?? '',
      sportType: json['sport_type'] ?? '',
      totalSlots: json['total_slots'] ?? 0,
      occupiedSlots: json['occupied_slots'] ?? 0,
      occupancyRate: (json['occupancy_rate'] ?? 0.0).toDouble(),
      isFull: json['is_full'] ?? false,
    );
  }
}

// ----------------------------------------------------------
// ActivityRecommendation
// ----------------------------------------------------------
class ActivityRecommendation {
  final String activityId;
  final String title;
  final String sportType;
  final String location;
  final String level;
  final int occupiedSlots;
  final int totalSlots;
  final double matchScore;

  ActivityRecommendation({
    required this.activityId,
    required this.title,
    required this.sportType,
    required this.location,
    required this.level,
    required this.occupiedSlots,
    required this.totalSlots,
    required this.matchScore,
  });

  factory ActivityRecommendation.fromJson(Map<String, dynamic> json) {
    return ActivityRecommendation(
      activityId: json['activity_id'] ?? '',
      title: json['title'] ?? '',
      sportType: json['sport_type'] ?? '',
      location: json['location'] ?? '',
      level: json['level'] ?? '',
      occupiedSlots: json['occupied_slots'] ?? 0,
      totalSlots: json['total_slots'] ?? 0,
      matchScore: (json['match_score'] ?? 0.0).toDouble(),
    );
  }
}

// ----------------------------------------------------------
// RankingEntry
// ----------------------------------------------------------
class RankingEntry {
  final int position;
  final String uid;
  final String name;
  final int totalActivities;
  final String? favoriteSport;
  final String? profilePic;

  RankingEntry({
    required this.position,
    required this.uid,
    required this.name,
    required this.totalActivities,
    this.favoriteSport,
    this.profilePic,
  });

  factory RankingEntry.fromJson(Map<String, dynamic> json) {
    return RankingEntry(
      position: json['position'] ?? 0,
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      totalActivities: json['total_activities'] ?? 0,
      favoriteSport: json['favorite_sport'],
      profilePic: json['profile_pic'],
    );
  }
}
