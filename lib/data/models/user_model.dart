import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required String id,
    required String email,
    required String name,
    required String role,
    String status = 'active',
    String? profileImage,
  }) : super(
         id: id,
         email: email,
         name: name,
         role: role,
         status: status,
         profileImage: profileImage,
       );

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      email: map['email'],
      name: map['name'],
      role: map['role'],
      status: map['status'] ?? 'active',
      profileImage: map['profile_image'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'status': status,
      'profile_image': profileImage,
    };
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
      status: user.status,
      profileImage: user.profileImage,
    );
  }
}
