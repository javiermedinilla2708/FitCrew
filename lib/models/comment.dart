import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String userId;
  final String userName;
  final String? userPic;
  final String text;
  final DateTime date;

  CommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPic,
    required this.text,
    required this.date,
  });

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
}