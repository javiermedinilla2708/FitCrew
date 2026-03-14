import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcrew/models/post.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';


class PostViewModel extends ChangeNotifier {
  File? _imageFile;
  String? _base64Image;
  bool _isLoading = false;

  File? get imageFile => _imageFile;
  bool get isLoading => _isLoading;

  // Seleccionar imagen de la galería
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800, // Importante para no exceder 1MB en Firestore
      imageQuality: 50,
    );

    if (pickedFile != null) {
      _imageFile = File(pickedFile.path);
      final bytes = await _imageFile!.readAsBytes();
      _base64Image = base64Encode(bytes);
      notifyListeners();
    }
  }

  // Publicar en Firestore
  Future<bool> uploadPost({
    required String description,
    required String sportType,
    required String level,
  }) async {
    if (description.isEmpty || _base64Image == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      // CORRECCIÓN: Uuid() no puede ser const
      var uuid = const Uuid(); 
      final String postId = uuid.v4();

      final newPost = Post(
        id: postId,
        userId: user?.uid ?? '',
        userName: user?.displayName ?? 'Usuario Fit',
        userPic: user?.photoURL,
        sportType: sportType,
        description: description,
        imageUrl: _base64Image,
        date: DateTime.now(),
        level: level,
      );
      Map<String, dynamic> postMap = newPost.toMap();
      postMap['date'] = FieldValue.serverTimestamp();
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .set(postMap);

      // Limpiar datos tras éxito
      _imageFile = null;
      _base64Image = null;
      return true;
    } catch (e) {
      print("Error en uploadPost: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}