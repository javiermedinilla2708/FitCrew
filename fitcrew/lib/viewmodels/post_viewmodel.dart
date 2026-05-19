// ============================================================
// lib/viewmodels/post_viewmodel.dart
// ViewModel que gestiona la creación y eliminación de posts.
// Maneja la selección de imagen desde galería, su conversión
// a Base64 y la publicación via PostService.
// ============================================================

import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcrew/models/post.dart';
import 'package:fitcrew/services/auth_services.dart';
import 'package:fitcrew/services/post_service.dart';

class PostViewModel extends ChangeNotifier {
  // ----------------------------------------------------------
  // DEPENDENCIAS
  // ----------------------------------------------------------
  final PostService _postService = PostService();
  final AuthService _authService = AuthService();

  // ----------------------------------------------------------
  // ESTADO INTERNO
  // ----------------------------------------------------------
  File? _imageFile = null; // Archivo de imagen seleccionado del dispositivo
  String? _base64Image = null; // Imagen codificada en Base64 para Firestore
  bool _isLoading = false;
  List<String> _userSports = [];

  // ----------------------------------------------------------
  // GETTERS PÚBLICOS
  // ----------------------------------------------------------
  File? get imageFile => _imageFile;
  bool get isLoading => _isLoading;
  List<String> get userSports => _userSports;

  // ----------------------------------------------------------
  // CARGAR DEPORTES FAVORITOS DEL USUARIO
  // Necesarios para mostrar las opciones de deporte
  // disponibles en el formulario de creación de post
  // ----------------------------------------------------------
  Future<void> loadUserSports() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _userSports = await _authService.getUserSports(uid);
    notifyListeners();
  }

  // ----------------------------------------------------------
  // SELECCIONAR IMAGEN DE LA GALERÍA
  // Limita el ancho a 800px y la calidad al 50% para reducir
  // el tamaño del Base64 almacenado en Firestore.
  // Nota: pendiente migrar a Firebase Storage
  // ----------------------------------------------------------
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

  // ----------------------------------------------------------
  // PUBLICAR POST
  // Requiere descripción e imagen seleccionada previamente.
  // Genera un UUID como ID del post antes de enviarlo a Firestore.
  // Devuelve true si se publicó correctamente, false si hubo error.
  // ----------------------------------------------------------
  Future<bool> uploadPost({
    required String description,
    required String sportType,
    required String level,
    String? location,
    List<Map<String, String>> taggedUsers = const [],
  }) async {
    if (description.isEmpty || _base64Image == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      final postId = const Uuid().v4();

      String? profilePicB64;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        profilePicB64 = doc.data()?['profilePic'];
      }

      final newPost = Post(
        id: postId,
        userId: user?.uid ?? '',
        userName: user?.displayName ?? 'Usuario Fit',
        userPic: user?.photoURL,
        profilePic: profilePicB64,
        sportType: sportType,
        description: description,
        imageUrl: _base64Image,
        date: DateTime.now(),
        level: level,
        location: location,
        taggedUsers: taggedUsers,
      );

      await _postService.createPost(newPost);
      _resetData();
      return true;
    } catch (e) {
      debugPrint("Error en uploadPost: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ----------------------------------------------------------
  // ELIMINAR POST
  // Delega en PostService y gestiona el estado de carga.
  // Devuelve true si se eliminó correctamente, false si falló.
  // ----------------------------------------------------------
  Future<bool> deletePost(String postId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _postService.deletePost(postId);
      return true;
    } catch (e) {
      debugPrint("Error al eliminar post en ViewModel: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ----------------------------------------------------------
  // RESETEAR ESTADO TRAS PUBLICAR
  // Limpia la imagen seleccionada para el siguiente post
  // ----------------------------------------------------------
  void _resetData() {
    _imageFile = null;
    _base64Image = null;
    notifyListeners();
  }
}
