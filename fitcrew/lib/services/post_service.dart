import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitcrew/models/post.dart';

class PostService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- CREAR POST ---
  Future<void> createPost(Post post) async {
    Map<String, dynamic> postMap = post.toMap();
    postMap['date'] = FieldValue.serverTimestamp();
    
    await _db.collection('posts').doc(post.id).set(postMap);
  }

  // --- ELIMINAR POST ---
  Future<void> deletePost(String postId) async {
    final postRef = _db.collection('posts').doc(postId);
    
    WriteBatch batch = _db.batch();

    final likes = await postRef.collection('likes').get();
    for (var doc in likes.docs) {
      batch.delete(doc.reference);
    }

    final comments = await postRef.collection('comments').get();
    for (var doc in comments.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(postRef);

    await batch.commit();
  }
}