// ============================================================
// lib/models/comment_model.dart
// Modelo de datos que representa un comentario de un post.
// Mapea los documentos de la subcolección 'comments' dentro
// de cada post en Firestore.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  // ----------------------------------------------------------
  // CAMPOS
  // ----------------------------------------------------------
  final String id; // ID del documento en Firestore
  final String userId; // UID del autor del comentario
  final String userName; // Nombre del autor en el momento de comentar
  final String? userPic; // URL de foto de perfil del autor
  final String text; // Contenido textual del comentario
  final DateTime date; // Fecha y hora del comentario

  const CommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPic,
    required this.text,
    required this.date,
  });

  // ----------------------------------------------------------
  // FACTORY — deserialización desde Firestore
  // El campo date siempre es Timestamp en Firestore ya que
  // se guarda con FieldValue.serverTimestamp() al crear.
  // ----------------------------------------------------------
  factory CommentModel.fromMap(Map<String, dynamic> map, String docId) {
    return CommentModel(
      id: docId,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Usuario',
      userPic: map['userPic'],
      text: map['text'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
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
      'userName': userName,
      'userPic': userPic,
      'text': text,
      'date': Timestamp.fromDate(date),
    };
  }
}
