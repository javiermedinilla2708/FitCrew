import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitcrew/models/post.dart';

class PostService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Subir un post a Firestore
  Future<void> createPost(Post post) async {
    Map<String, dynamic> postMap = post.toMap();
    // Usamos serverTimestamp para consistencia global
    postMap['date'] = FieldValue.serverTimestamp();
    
    await _db.collection('posts').doc(post.id).set(postMap);
  }

  // Podrías añadir aquí: deletePost, likePost, etc.
}