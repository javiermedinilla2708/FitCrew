// ============================================================
// lib/services/post_service.dart
// Servicio de acceso a datos para la colección posts de
// Firestore. Gestiona la creación y eliminación de posts
// incluyendo sus subcolecciones de likes y comentarios.
// Sigue el patrón Repository para desacoplar el acceso
// a datos de la lógica de negocio del ViewModel.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitcrew/models/post.dart';

class PostService {
  // ----------------------------------------------------------
  // INSTANCIA DE FIRESTORE
  // Se usa la instancia singleton de FirebaseFirestore para
  // evitar crear múltiples conexiones a la base de datos
  // ----------------------------------------------------------
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ----------------------------------------------------------
  // CREAR POST
  // Guarda el post en Firestore usando el ID generado
  // previamente en el ViewModel con uuid.
  // La fecha se sobreescribe con FieldValue.serverTimestamp()
  // para usar el reloj del servidor de Firebase en lugar del
  // reloj local del dispositivo, garantizando consistencia
  // en el ordenamiento del feed aunque el dispositivo tenga
  // la hora incorrecta.
  // ----------------------------------------------------------
  Future<void> createPost(Post post) async {
    // Serializa el modelo Post a Map para Firestore
    Map<String, dynamic> postMap = post.toMap();

    // Sobreescribe la fecha con el timestamp del servidor
    // para garantizar consistencia entre dispositivos
    postMap['date'] = FieldValue.serverTimestamp();

    // Usa el ID del post como ID del documento en lugar de
    // dejar que Firestore genere uno automáticamente,
    // lo que permite referenciar el post por su ID conocido
    await _db.collection('posts').doc(post.id).set(postMap);
  }

  // ----------------------------------------------------------
  // ELIMINAR POST
  // Elimina el post y todas sus subcolecciones en una sola
  // operación atómica usando WriteBatch de Firestore.
  //
  // IMPORTANTE: Firestore no elimina subcolecciones
  // automáticamente al borrar un documento padre. Si solo
  // se borrara el documento del post, los documentos de
  // likes y comentarios quedarían huérfanos en Firestore
  // ocupando espacio y generando costes innecesarios.
  //
  // El batch garantiza que todas las operaciones se ejecutan
  // juntas o ninguna se ejecuta, evitando estados
  // inconsistentes donde el post se borra pero quedan
  // likes o comentarios huérfanos.
  // ----------------------------------------------------------
  Future<void> deletePost(String postId) async {
    // Referencia al documento del post a eliminar
    final postRef = _db.collection('posts').doc(postId);

    // Inicializa el batch para agrupar todas las operaciones
    // en una sola transacción atómica
    WriteBatch batch = _db.batch();

    // Paso 1: Obtiene todos los likes de la subcolección
    // y los añade al batch para eliminarlos
    final likes = await postRef.collection('likes').get();
    for (var doc in likes.docs) {
      batch.delete(doc.reference);
    }

    // Paso 2: Obtiene todos los comentarios de la
    // subcolección y los añade al batch para eliminarlos
    final comments = await postRef.collection('comments').get();
    for (var doc in comments.docs) {
      batch.delete(doc.reference);
    }

    // Paso 3: Añade la eliminación del documento principal
    // del post al batch. Se hace al final para mantener
    // el orden lógico de limpieza de datos
    batch.delete(postRef);

    // Ejecuta todas las operaciones del batch de forma
    // atómica en Firestore. Si alguna falla, ninguna
    // se aplica y Firestore lanza una excepción
    await batch.commit();
  }
}
