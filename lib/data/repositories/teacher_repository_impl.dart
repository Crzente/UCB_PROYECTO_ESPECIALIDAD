import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../domain/entities/teacher.dart';
import '../../domain/repositories/teacher_repository.dart';
import '../models/teacher_model.dart';
import '../../core/utils/rank_sorter.dart';

class TeacherRepositoryImpl implements TeacherRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<Teacher>> getTeachers() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT t.*, 
             u.name as user_name, u.email as user_email, u.status as user_status
      FROM teachers t
      JOIN users u ON t.user_id = u.id
    ''');

    final teachers = result.map((map) => TeacherModel.fromMap(map)).toList();
    return RankSorter.sortTeachers(teachers);
  }

  @override
  Future<Teacher?> getTeacherById(String id) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT t.*, 
             u.name as user_name, u.email as user_email, u.status as user_status
      FROM teachers t
      JOIN users u ON t.user_id = u.id
      WHERE t.id = ?
    ''',
      [id],
    );

    if (result.isNotEmpty) {
      return TeacherModel.fromMap(result.first);
    }
    return null;
  }

  @override
  Future<Teacher?> getTeacherByUserId(String userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT t.*, 
             u.name as user_name, u.email as user_email, u.status as user_status
      FROM teachers t
      JOIN users u ON t.user_id = u.id
      WHERE t.user_id = ?
    ''',
      [userId],
    );

    if (result.isNotEmpty) {
      return TeacherModel.fromMap(result.first);
    }
    return null;
  }

  @override
  Future<void> createTeacher(Teacher teacher) async {
    final db = await _dbHelper.database;
    final teacherModel = teacher is TeacherModel
        ? teacher
        : TeacherModel(
            id: teacher.id,
            userId: teacher.userId,
            teacherCode: teacher.teacherCode,
            status: teacher.status,
            birthDate: teacher.birthDate,
            identityCard: teacher.identityCard,
            militaryCard: teacher.militaryCard,
            insuranceCard: teacher.insuranceCard,
            phone: teacher.phone,
            grade: teacher.grade,
            specialty: teacher.specialty,
            graduationYear: teacher.graduationYear,
            profileImage: teacher.profileImage,
          );

    await db.insert(
      'teachers',
      teacherModel.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateTeacher(Teacher teacher) async {
    final db = await _dbHelper.database;
    final teacherModel = teacher is TeacherModel
        ? teacher
        : TeacherModel(
            id: teacher.id,
            userId: teacher.userId,
            teacherCode: teacher.teacherCode,
            status: teacher.status,
            birthDate: teacher.birthDate,
            identityCard: teacher.identityCard,
            militaryCard: teacher.militaryCard,
            insuranceCard: teacher.insuranceCard,
            phone: teacher.phone,
            grade: teacher.grade,
            specialty: teacher.specialty,
            graduationYear: teacher.graduationYear,
            profileImage: teacher.profileImage,
          );

    await db.update(
      'teachers',
      teacherModel.toMap(),
      where: 'id = ?',
      whereArgs: [teacher.id],
    );
  }

  @override
  Future<void> deleteTeacher(String id) async {
    final db = await _dbHelper.database;
    final result = await db.query('teachers', where: 'id = ?', whereArgs: [id]);
    String? userId;
    if (result.isNotEmpty) {
      userId = result.first['user_id'] as String?;
    }

    await db.transaction((txn) async {
      await txn.delete('teachers', where: 'id = ?', whereArgs: [id]);
      if (userId != null) {
        await txn.delete('users', where: 'id = ?', whereArgs: [userId]);
      }
    });
  }
}
