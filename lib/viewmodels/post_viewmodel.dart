import 'dart:convert';
import 'dart:io';
import 'package:fitcrew/services/auth_services.dart';
import 'package:fitcrew/services/post_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcrew/models/post.dart';

class PostViewModel extends ChangeNotifier {
  // Inyectamos los servicios
  final PostService _postService = PostService();
  final AuthService _authService = AuthService();

  File? _imageFile;
  String? _base64Image;
  bool _isLoading = false;
  List<String> _userSports = [];

  // Getters
  File? get imageFile => _imageFile;
  bool get isLoading => _isLoading;
  List<String> get userSports => _userSports;

  // --- CARGAR DEPORTES ---
  Future<void> loadUserSports() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Delegamos la carga de datos al AuthService que ya tiene el método
    _userSports = await _authService.getUserSports(uid);
    notifyListeners();
  }

  // --- SELECCIONAR IMAGEN ---
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      _imageFile = File(pickedFile.path);
      final bytes = await _imageFile!.readAsBytes();
      _base64Image = base64Encode(bytes);
      notifyListeners();
    }
  }

  // --- PUBLICAR POST ---
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
      final String postId = const Uuid().v4();

      final newPost = Post(
        id: postId,
        userId: user?.uid ?? '',
        userName: user?.displayName ?? 'Usuario Fit',
        userPic: user?.photoURL,
        sportType: sportType,
        description: description,
        imageUrl: _base64Image,
        date: DateTime.now(), // El servicio lo cambiará por ServerTimestamp
        level: level,
      );

      // Usamos el servicio en lugar de llamar a Firestore aquí
      await _postService.createPost(newPost);

      // Limpiar datos tras éxito
      _resetData();
      return true;
    } catch (e) {
      print("Error en PostViewModel: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _resetData() {
    _imageFile = null;
    _base64Image = null;
  }
}