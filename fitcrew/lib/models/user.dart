// ============================================================
// lib/models/app_user.dart
// Modelo de datos que representa un usuario de FitCrew.
// Mapea el documento de la colección 'users' en Firestore
// e incluye métodos de serialización y copia inmutable.
// ============================================================

class AppUser {
  // ----------------------------------------------------------
  // CAMPOS
  // ----------------------------------------------------------
  final String uid; // UID único de Firebase Auth
  final String name; // Nombre visible del usuario
  final String email; // Correo electrónico normalizado
  final List<String> favoriteSports; // Deportes seleccionados en el onboarding
  final String? profilePic; // URL de foto de perfil (pendiente Storage)

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.favoriteSports,
    this.profilePic,
  });

  // ----------------------------------------------------------
  // FACTORY — deserialización desde Firestore
  // Convierte un Map<String, dynamic> del documento Firestore
  // en una instancia de AppUser. Usa valores por defecto para
  // evitar null safety issues si algún campo falta en el doc.
  // ----------------------------------------------------------
  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      favoriteSports: List<String>.from(data['favoriteSports'] ?? []),
      profilePic: data['profilePic'],
    );
  }

  // ----------------------------------------------------------
  // SERIALIZACIÓN — conversión a Map para Firestore
  // Convierte la instancia a Map<String, dynamic> listo para
  // ser almacenado como documento en Firestore.
  // ----------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'favoriteSports': favoriteSports,
      'profilePic': profilePic,
    };
  }

  // ----------------------------------------------------------
  // COPY WITH — copia inmutable con campos modificados
  // Permite crear una nueva instancia modificando solo los campos
  // necesarios sin mutar el objeto original, siguiendo el patrón
  // de inmutabilidad recomendado en Flutter.
  // ----------------------------------------------------------
  AppUser copyWith({
    String? uid,
    String? name,
    String? email,
    List<String>? favoriteSports,
    String? profilePic,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      favoriteSports: favoriteSports ?? this.favoriteSports,
      profilePic: profilePic ?? this.profilePic,
    );
  }
}
