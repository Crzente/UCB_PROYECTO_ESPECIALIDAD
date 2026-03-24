import '../entities/user.dart';

abstract class UserRepository {
  Future<User?> login(String email, String password);
  Future<User> register(User user, String password);
  Future<User?> getUserById(String id);
  Future<List<User>> getUsersByRole(String role);
  Future<List<User>> getAllUsers();
  Future<void> deleteUser(String id);
  Future<void> updateUser(User user, {String? password});
}
