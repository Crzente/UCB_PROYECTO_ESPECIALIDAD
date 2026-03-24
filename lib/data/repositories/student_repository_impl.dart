import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import '../../core/database/database_helper.dart';
import '../../domain/entities/student.dart';
import '../../domain/repositories/student_repository.dart';
import '../models/student_model.dart';
import '../../core/utils/rank_sorter.dart';

class StudentRepositoryImpl implements StudentRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<Student>> getStudents() async {
    final db = await _dbHelper.database;
    // Join with users to get name/email info
    final result = await db.rawQuery('''
      SELECT s.*, u.name as user_name, u.email as user_email, u.status as user_status
      FROM students s
      JOIN users u ON s.user_id = u.id
    ''');

    final students = result.map((map) => StudentModel.fromMap(map)).toList();
    return RankSorter.sortStudents(students);
  }

  @override
  Future<Student?> getStudentById(String id) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT s.*, u.name as user_name, u.email as user_email, u.status as user_status
      FROM students s
      JOIN users u ON s.user_id = u.id
      WHERE s.id = ?
    ''',
      [id],
    );

    if (result.isNotEmpty) {
      return StudentModel.fromMap(result.first);
    }
    return null;
  }

  @override
  Future<Student?> getStudentByUserId(String userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT s.*, u.name as user_name, u.email as user_email, u.status as user_status
      FROM students s
      JOIN users u ON s.user_id = u.id
      WHERE s.user_id = ?
    ''',
      [userId],
    );

    if (result.isNotEmpty) {
      return StudentModel.fromMap(result.first);
    }
    return null;
  }

  @override
  Future<void> createStudent(Student student) async {
    final db = await _dbHelper.database;
    // Fix: Handle Student entity gracefully
    final studentModel = student is StudentModel
        ? student
        : StudentModel(
            id: student.id,
            userId: student.userId,
            studentCode: student.studentCode,
            status: student.status,
            birthDate: student.birthDate,
            identityCard: student.identityCard,
            militaryCard: student.militaryCard,
            insuranceCard: student.insuranceCard,
            phone: student.phone,
            grade: student.grade,
            specialty: student.specialty,
            graduationYear: student.graduationYear,
            courseSeniority: student.courseSeniority,
            profileImage: student.profileImage,
          );

    debugPrint("Inserting student: ${studentModel.toMap()}");
    await db.insert(
      'students',
      studentModel.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateStudent(Student student) async {
    final db = await _dbHelper.database;
    // Fix: Handle Student entity gracefully
    final studentModel = student is StudentModel
        ? student
        : StudentModel(
            id: student.id,
            userId: student.userId,
            studentCode: student.studentCode,
            status: student.status,
            birthDate: student.birthDate,
            identityCard: student.identityCard,
            militaryCard: student.militaryCard,
            insuranceCard: student.insuranceCard,
            phone: student.phone,
            grade: student.grade,
            specialty: student.specialty,
            graduationYear: student.graduationYear,
            courseSeniority: student.courseSeniority,
            profileImage: student.profileImage,
          );

    await db.update(
      'students',
      studentModel.toMap(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }

  @override
  Future<void> deleteStudent(String id) async {
    final db = await _dbHelper.database;
    // We only delete the STUDENT record, not the USER?
    // User requested "desvincular o eliminar".
    // If we delete the student record, the User remains but is no longer a student.
    // This seems correct for "Desvincular".
    // "Eliminar" might mean deleting user too, but let's stick to student record for now.
    await db.delete('students', where: 'id = ?', whereArgs: [id]);
  }
}
