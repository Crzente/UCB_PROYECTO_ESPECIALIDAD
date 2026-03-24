import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../models/user_model.dart';
import 'package:uuid/uuid.dart';

class UserRepositoryImpl implements UserRepository {
  final DatabaseHelper dbHelper;

  UserRepositoryImpl({required this.dbHelper});

  @override
  Future<User?> login(String email, String password) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<User> register(User user, String password) async {
    final db = await dbHelper.database;
    final userModel = UserModel.fromEntity(user);
    // Explicitly adding password as it's not in the User entity but needed for DB
    final map = userModel.toMap();
    map['password'] = password;

    // If ID is empty, generate one
    if (map['id'] == null || map['id'].isEmpty) {
      map['id'] = const Uuid().v4();
    }

    await db.insert('users', map, conflictAlgorithm: ConflictAlgorithm.fail);

    // Return with the generated ID
    return UserModel.fromMap(map);
  }

  @override
  Future<User?> getUserById(String id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<List<User>> getAllUsers() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    return List.generate(maps.length, (i) => UserModel.fromMap(maps[i]));
  }

  @override
  Future<List<User>> getUsersByRole(String role) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'role = ?',
      whereArgs: [role],
    );
    return List.generate(maps.length, (i) => UserModel.fromMap(maps[i]));
  }

  @override
  Future<void> deleteUser(String id) async {
    final db = await dbHelper.database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> updateUser(User user, {String? password}) async {
    final db = await dbHelper.database;
    final userModel = UserModel.fromEntity(user);
    final map = userModel.toMap();

    if (password != null && password.isNotEmpty) {
      map['password'] = password;
    }

    await db.update('users', map, where: 'id = ?', whereArgs: [user.id]);
  }
}
