// ============================================================
// lib/services/activity_service.dart
// Servicio que gestiona las operaciones CRUD de actividades
// deportivas en Firestore, incluyendo la lógica de
// apuntarse y desapuntarse con transacciones atómicas
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcrew/models/sport_activity.dart';

class ActivityService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ----------------------------------------------------------
  // CREAR ACTIVIDAD
  // Devuelve el ID generado por Firestore o null si falla
  // ----------------------------------------------------------
  Future<String?> createActivity(SportActivity activity) async {
    try {
      final docRef = await _db.collection('activities').add(activity.toMap());
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteActivity(String activityId) async {
    await _db.collection('activities').doc(activityId).delete();
  }

  // ----------------------------------------------------------
  // STREAM DE ACTIVIDADES EN TIEMPO REAL
  // Ordenadas por fecha ascendente (próximas primero)
  // ----------------------------------------------------------
  Stream<List<SportActivity>> getActivitiesStream() {
    return _db
        .collection('activities')
        .orderBy('date', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SportActivity.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // ----------------------------------------------------------
  // APUNTARSE A UNA ACTIVIDAD
  // Usa transacción atómica para evitar condiciones de carrera
  // al actualizar occupiedSlots y participants simultáneamente
  // ----------------------------------------------------------
  Future<void> joinActivity(String activityId) async {
    final user = _auth.currentUser;
    if (user == null) throw "Debes iniciar sesión";

    final ref = _db.collection('activities').doc(activityId);

    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) throw "Evento no encontrado";

      final data = snapshot.data() as Map<String, dynamic>;
      final int occupied = data['occupiedSlots'] ?? 0;
      final int total = data['totalSlots'] ?? 0;
      final List<String> participants = List<String>.from(
        data['participants'] ?? [],
      );

      if (participants.contains(user.uid)) throw "Ya estás apuntado";
      if (occupied >= total) throw "El evento está lleno";

      transaction.update(ref, {
        'occupiedSlots': occupied + 1,
        'participants': [...participants, user.uid],
      });
    });
  }

  // ----------------------------------------------------------
  // DESAPUNTARSE DE UNA ACTIVIDAD
  // Usa transacción atómica para decrementar occupiedSlots
  // y eliminar al usuario de la lista de participants
  // ----------------------------------------------------------
  Future<bool> leaveActivity(String activityId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    try {
      await _db.runTransaction((tx) async {
        final ref = _db.collection('activities').doc(activityId);
        final snap = await tx.get(ref);
        final data = snap.data()!;

        final int occupied = data['occupiedSlots'] as int;
        final List<String> participants = List<String>.from(
          data['participants'] ?? [],
        );

        participants.remove(uid);

        tx.update(ref, {
          'occupiedSlots': occupied - 1,
          'participants': participants,
        });
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
