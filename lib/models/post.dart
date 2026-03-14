import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userId;
  final String userName;
  final String? userPic;
  final String sportType;
  final String description;
  final String? imageUrl;
  final DateTime date;
  final int likesCount;
  final int commentsCount;
  final String level;

  Post({
    required this.id,
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

  factory Post.fromMap(Map<String, dynamic> map, String docId) {
    return Post(
      id: docId,
      userId: map['userId'] ?? '',
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

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
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
}