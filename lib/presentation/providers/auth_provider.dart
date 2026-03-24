import 'package:flutter/material.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/entities/user.dart';

class AuthProvider extends ChangeNotifier {
  final UserRepository userRepository;
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({required this.userRepository});

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _currentUser != null;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await userRepository.login(email, password);
      if (user != null) {
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Credenciales inválidas';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error al iniciar sesión: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
  }

  // Temporary method to register users for testing
  Future<bool> register(
    String email,
    String password,
    String name,
    String role,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      final newUser = User(id: '', email: email, name: name, role: role);
      final createdUser = await userRepository.register(newUser, password);
      _currentUser = createdUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
