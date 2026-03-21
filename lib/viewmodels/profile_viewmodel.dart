import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProfileViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Borrar datos de Firestore
      await _db.collection('users').doc(user.uid).delete();
      // 2. Borrar el usuario de Auth
      await user.delete();
    } catch (e) {
      rethrow; // El UI se encargará de mostrar el error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}