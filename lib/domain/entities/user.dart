class User {
  final String id;
  final String email;
  final String name;
  final String role; // 'admin', 'teacher', 'student'
  final String? profileImage;
  final String status; // 'active', 'blocked'

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.status = 'active',
    this.profileImage,
  });

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? status,
    String? profileImage,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      status: status ?? this.status,
      profileImage: profileImage ?? this.profileImage,
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isTeacher => role == 'teacher';
  bool get isStudent => role == 'student';
  bool get isActive => status == 'active';
}
