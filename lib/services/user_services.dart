import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Crear perfil inicial
  Future<void> createUserData(String uid, String name, String email) async {
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'favoriteSports': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Obtener deportes
  Future<List<String>> getUserSports(String uid) async {
    DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return List<String>.from(doc.get('favoriteSports') ?? []);
    }
    return [];
  }

  // Actualizar deportes
  Future<void> updateFavoriteSports(String uid, List<String> sports) async {
    await _db.collection('users').doc(uid).update({'favoriteSports': sports});
  }

  // En UserService.dart
  Future<void> updateSetupComplete(String uid) async {
    await _db.collection('users').doc(uid).update({'setupComplete': true});
  }
}
