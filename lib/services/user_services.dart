import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createUserData(String uid, String name, String email) async {
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'favoriteSports': [],
      'createdAt': FieldValue.serverTimestamp(),
      'profilePic': null,
      'bio': "",
    });
  }

  Future<List<String>> getUserSports(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return List<String>.from(doc.get('favoriteSports') ?? []);
    }
    return [];
  }

  Future<void> updateFavoriteSports(String uid, List<String> sports) async {
    await _db.collection('users').doc(uid).update({'favoriteSports': sports});
  }

  Future<void> updateSetupComplete(String uid) async {
    await _db.collection('users').doc(uid).update({'setupComplete': true});
  }

  Future<void> deleteUserData(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }
}
