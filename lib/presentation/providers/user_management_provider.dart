import 'package:flutter/material.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import 'package:uuid/uuid.dart';

class UserManagementProvider extends ChangeNotifier {
  final UserRepository userRepository;

  List<User> _users = [];
  bool _isLoading = false;

  UserManagementProvider({required this.userRepository});

  List<User> get users => _users;
  bool get isLoading => _isLoading;

  Future<void> loadUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      _users = await userRepository.getAllUsers();
    } catch (e) {
      debugPrint("Error loading users: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addUser(
    String name,
    String email,
    String password,
    String role, {
    String? id,
  }) async {
    final newUser = User(
      id: id ?? const Uuid().v4(),
      name: name,
      email: email,
      role: role,
    );
    await userRepository.register(newUser, password);
    await loadUsers();
  }

  Future<void> updateUser(User user, {String? password}) async {
    await userRepository.updateUser(user, password: password);
    await loadUsers();
  }

  Future<void> deleteUser(String id) async {
    await userRepository.deleteUser(id);
    await loadUsers();
  }

  Future<void> resetPassword(String userId, String newPassword) async {
    // We need to fetch the user first to get the current object, or just pass the ID if the repo supported just updating password.
    // However, our repo update takes a User object.
    final user = _users.firstWhere((u) => u.id == userId);
    await userRepository.updateUser(user, password: newPassword);
    // No need to reload users if only password changed, but good for consistency
  }
}
