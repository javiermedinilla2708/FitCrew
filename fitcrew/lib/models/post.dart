// ============================================================
// lib/models/post.dart
// Modelo de datos que representa un post del feed social.
// Mapea el documento de la colección 'posts' en Firestore.
// Los likes y comentarios se gestionan en subcolecciones
// separadas en tiempo real, por lo que likesCount y
// commentsCount son campos auxiliares no siempre actualizados.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  // ----------------------------------------------------------
  // CAMPOS
  // ----------------------------------------------------------
  final String id; // ID del documento en Firestore
  final String? profilePic; // Foto del usuario
  final String userId; // UID del autor del post
  final String userName; // Nombre del autor en el momento de publicar
  final String? userPic; // URL de foto de perfil del autor
  final String sportType; // Deporte asociado al post
  final String description; // Texto descriptivo del logro
  final String? imageUrl; // Imagen en Base64 (pendiente migrar a Storage)
  final DateTime date; // Fecha y hora de publicación
  final int likesCount; // Contador auxiliar de likes
  final int commentsCount; // Contador auxiliar de comentarios
  final String level; // Nivel del deporte (ej: "Intermedio")

  const Post({
    required this.id,
    this.profilePic,
    required this.userId,
    required this.userName,
    this.userPic,
    required this.sportType,
    required this.description,
    this.imageUrl,
    required this.date,
    this.likesCount = 0,
    this.commentsCount = 0,
    required this.level,
  });

  // ----------------------------------------------------------
  // FACTORY — deserialización desde Firestore
  // El campo date se convierte desde Timestamp de Firestore.
  // Si no existe, se usa DateTime.now() como fallback.
  // ----------------------------------------------------------
  factory Post.fromMap(Map<String, dynamic> map, String docId) {
    return Post(
      id: docId,
      userId: map['userId'] ?? '',
      profilePic: map['profilePic'],
      userName: map['userName'] ?? 'Usuario Fit',
      userPic: map['userPic'],
      sportType: map['sportType'] ?? 'Otros',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      date: map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : DateTime.now(),
      likesCount: map['likesCount'] ?? 0,
      commentsCount: map['commentsCount'] ?? 0,
      level: map['level'] ?? 'Intermedio',
    );
  }

  // ----------------------------------------------------------
  // SERIALIZACIÓN — conversión a Map para Firestore
  // Nota: el campo 'id' no se incluye porque Firestore lo
  // gestiona como ID del documento, no como campo interno.
  // ----------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'profilePic': profilePic,
      'userName': userName,
      'userPic': userPic,
      'sportType': sportType,
      'description': description,
      'imageUrl': imageUrl,
      'date': Timestamp.fromDate(date),
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'level': level,
    };
  }

  // ----------------------------------------------------------
  // COPY WITH — copia inmutable con campos modificados
  // ----------------------------------------------------------
  Post copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPic,
    String? sportType,
    String? description,
    String? imageUrl,
    DateTime? date,
    int? likesCount,
    int? commentsCount,
    String? level,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPic: userPic ?? this.userPic,
      sportType: sportType ?? this.sportType,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      date: date ?? this.date,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      level: level ?? this.level,
    );
  }
}
