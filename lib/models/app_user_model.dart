class AppUserModel {
  const AppUserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
  });

  final String uid;
  final String email;
  final String displayName;
  final String role;

  bool get isAdmin => role.toLowerCase() == 'admin';

  factory AppUserModel.fromMap(Map<String, dynamic> map) {
    return AppUserModel(
      uid: (map['uid'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      displayName: (map['displayName'] ?? '') as String,
      role: (map['role'] ?? 'user') as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role,
    };
  }
}
