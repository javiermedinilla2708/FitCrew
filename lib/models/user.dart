class AppUser {
  final String uid;
  final String name;
  final String email;
  final List<String> favoriteSports;
  final String? profilePic;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.favoriteSports,
    this.profilePic,
  });

  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      favoriteSports: List<String>.from(data['favoriteSports'] ?? []),
      profilePic: data['profilePic'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'favoriteSports': favoriteSports,
      'profilePic': profilePic,
    };
  }

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
