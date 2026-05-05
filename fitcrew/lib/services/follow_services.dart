// ============================================================
// lib/services/follow_service.dart
// Gestiona el sistema de seguimiento entre usuarios:
// enviar solicitudes, aceptar, rechazar y consultar estado
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcrew/services/notification_service.dart';
import 'package:flutter/material.dart';

class FollowService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? _currentUid = FirebaseAuth.instance.currentUser?.uid;
  final NotificationService _notifService = NotificationService();

  // ----------------------------------------------------------
  // ENVIAR SOLICITUD DE SEGUIMIENTO
  // Genera notificación al receptor
  // ----------------------------------------------------------
  Future<bool> sendFollowRequest(String toUid, String toName) async {
    if (_currentUid == null) return false;
    try {
      // Comprobamos si ya existe una solicitud pendiente
      final existing = await _db
          .collection('follow_requests')
          .where('fromUid', isEqualTo: _currentUid)
          .where('toUid', isEqualTo: toUid)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existing.docs.isNotEmpty) return false;

      // Obtenemos el nombre del usuario actual
      final currentUserDoc = await _db
          .collection('users')
          .doc(_currentUid)
          .get();
      final fromName = currentUserDoc.data()?['name'] ?? 'Usuario';

      await _db.collection('follow_requests').add({
        'fromUid': _currentUid,
        'toUid': toUid,
        'fromName': fromName,
        'toName': toName,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Notificar al receptor
      await _notifService.notifyFollowRequest(toUid: toUid, fromName: fromName);

      return true;
    } catch (e) {
      return false;
    }
  }

  // ----------------------------------------------------------
  // CANCELAR SOLICITUD ENVIADA
  // ----------------------------------------------------------
  Future<bool> cancelFollowRequest(String toUid) async {
    if (_currentUid == null) return false;
    try {
      final requests = await _db
          .collection('follow_requests')
          .where('fromUid', isEqualTo: _currentUid)
          .where('toUid', isEqualTo: toUid)
          .where('status', isEqualTo: 'pending')
          .get();

      for (final doc in requests.docs) {
        await doc.reference.delete();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // ----------------------------------------------------------
  // ACEPTAR SOLICITUD DE SEGUIMIENTO
  // Genera notificación al emisor original
  // ----------------------------------------------------------
  Future<bool> acceptFollowRequest(String requestId, String fromUid) async {
    if (_currentUid == null) return false;
    try {
      final batch = _db.batch();

      // Actualizar estado de la solicitud
      final requestRef = _db.collection('follow_requests').doc(requestId);
      batch.update(requestRef, {'status': 'accepted'});

      // Añadir a followers del usuario actual
      final followerRef = _db
          .collection('users')
          .doc(_currentUid)
          .collection('followers')
          .doc(fromUid);
      batch.set(followerRef, {'timestamp': FieldValue.serverTimestamp()});

      // Añadir a following del usuario que envió la solicitud
      final followingRef = _db
          .collection('users')
          .doc(fromUid)
          .collection('following')
          .doc(_currentUid);
      batch.set(followingRef, {'timestamp': FieldValue.serverTimestamp()});

      await batch.commit();

      // Notificar al emisor que su solicitud fue aceptada
      final currentUserDoc = await _db
          .collection('users')
          .doc(_currentUid)
          .get();
      final myName = currentUserDoc.data()?['name'] ?? 'Usuario';

      await _notifService.notifyFollowAccepted(
        toUid: fromUid,
        fromName: myName,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  // ----------------------------------------------------------
  // RECHAZAR SOLICITUD DE SEGUIMIENTO
  // ----------------------------------------------------------
  Future<bool> rejectFollowRequest(String requestId) async {
    if (_currentUid == null) return false;
    try {
      await _db.collection('follow_requests').doc(requestId).update({
        'status': 'rejected',
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ----------------------------------------------------------
  // DEJAR DE SEGUIR A UN USUARIO
  // ----------------------------------------------------------
  Future<bool> unfollow(String targetUid) async {
    if (_currentUid == null) return false;
    try {
      final batch = _db.batch();

      batch.delete(
        _db
            .collection('users')
            .doc(_currentUid)
            .collection('following')
            .doc(targetUid),
      );

      batch.delete(
        _db
            .collection('users')
            .doc(targetUid)
            .collection('followers')
            .doc(_currentUid),
      );

      final requests = await _db
          .collection('follow_requests')
          .where('fromUid', isEqualTo: _currentUid)
          .where('toUid', isEqualTo: targetUid)
          .where('status', isEqualTo: 'accepted')
          .get();

      for (final doc in requests.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ----------------------------------------------------------
  // SEGUIR DIRECTAMENTE SIN SOLICITUD
  // Se usa cuando ya existe una relación de seguimiento mutua
  // por ejemplo tras aceptar una solicitud recibida
  // ----------------------------------------------------------
  Future<bool> followDirectly(String targetUid) async {
    if (_currentUid == null) return false;
    try {
      // Comprobar si ya le sigue para evitar duplicados
      final alreadyFollowing = await _db
          .collection('users')
          .doc(_currentUid)
          .collection('following')
          .doc(targetUid)
          .get();

      if (alreadyFollowing.exists) return true;

      final batch = _db.batch();

      // Añadir a following del usuario actual
      batch.set(
        _db
            .collection('users')
            .doc(_currentUid)
            .collection('following')
            .doc(targetUid),
        {'timestamp': FieldValue.serverTimestamp()},
      );

      // Añadir a followers del usuario objetivo
      batch.set(
        _db
            .collection('users')
            .doc(targetUid)
            .collection('followers')
            .doc(_currentUid),
        {'timestamp': FieldValue.serverTimestamp()},
      );

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint("Error en followDirectly: $e");
      return false;
    }
  }

  // ----------------------------------------------------------
  // CONSULTAR ESTADO DE SEGUIMIENTO
  // Devuelve: "none" | "pending" | "following"
  // ----------------------------------------------------------
  Future<String> getFollowStatus(String targetUid) async {
    if (_currentUid == null) return 'none';
    try {
      final followingDoc = await _db
          .collection('users')
          .doc(_currentUid)
          .collection('following')
          .doc(targetUid)
          .get();

      if (followingDoc.exists) return 'following';

      final pendingRequest = await _db
          .collection('follow_requests')
          .where('fromUid', isEqualTo: _currentUid)
          .where('toUid', isEqualTo: targetUid)
          .where('status', isEqualTo: 'pending')
          .get();

      if (pendingRequest.docs.isNotEmpty) return 'pending';

      return 'none';
    } catch (e) {
      return 'none';
    }
  }

  // ----------------------------------------------------------
  // STREAM: SOLICITUDES RECIBIDAS PENDIENTES
  // ----------------------------------------------------------
  Stream<QuerySnapshot> getPendingRequestsStream() {
    if (_currentUid == null) return const Stream.empty();
    return _db
        .collection('follow_requests')
        .where('toUid', isEqualTo: _currentUid)
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // ----------------------------------------------------------
  // STREAM: CONTADOR DE SEGUIDORES EN TIEMPO REAL
  // ----------------------------------------------------------
  Stream<int> getFollowersCountStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('followers')
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ----------------------------------------------------------
  // STREAM: CONTADOR DE SEGUIDOS EN TIEMPO REAL
  // ----------------------------------------------------------
  Stream<int> getFollowingCountStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('following')
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ----------------------------------------------------------
  // BUSCAR USUARIOS POR NOMBRE
  // ----------------------------------------------------------
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final results = await _db
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();

      return results.docs
          .where((doc) => doc.id != _currentUid)
          .map((doc) => {'uid': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      return [];
    }
  }
}
