class User {
  final String uid;
  final String name;
  final String email;
  final List<String> favoriteSports;
  final String? profilePic;

  User({
    required this.uid,
    required this.name,
    required this.email,
    required this.favoriteSports,
    this.profilePic,
  });

  factory User.fromMap(Map<String, dynamic> data) {
    return User(
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
}