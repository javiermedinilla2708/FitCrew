import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcrew/models/sport_activity.dart';

class ActivityService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createActivity(SportActivity activity) async {
    try {
      final map = activity.toMap();
      map['createdAt'] = FieldValue.serverTimestamp();
      map['participants'] = [];
      await _db.collection('activities').add(map);
    } catch (e) {
      throw Exception("Error al crear actividad: $e");
    }
  }

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

  Future<void> joinActivity(String activityId) async {
    final user = _auth.currentUser;
    if (user == null) throw "Debes iniciar sesión";

    final ref = _db.collection('activities').doc(activityId);

    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) throw "Evento no encontrado";

      final data = snapshot.data() as Map<String, dynamic>;
      final int currentOccupied = data['occupiedSlots'] ?? 0;
      final int total = data['totalSlots'] ?? 0;
      final List<String> participants = List<String>.from(
        data['participants'] ?? [],
      );

      if (participants.contains(user.uid)) throw "Ya estás apuntado";
      if (currentOccupied >= total) throw "El evento está lleno";

      transaction.update(ref, {
        'occupiedSlots': currentOccupied + 1,
        'participants': [...participants, user.uid],
      });
    });
  }

  Future<bool> leaveActivity(String activityId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    try {
      await _db.runTransaction((tx) async {
        final ref = _db.collection('activities').doc(activityId);
        final snap = await tx.get(ref);
        final data = snap.data()!;
        final occupied = (data['occupiedSlots'] as int);
        final participants = List<String>.from(data['participants'] ?? []);
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
