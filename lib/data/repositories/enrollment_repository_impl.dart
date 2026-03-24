import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../domain/entities/enrollment.dart';
import '../../domain/repositories/enrollment_repository.dart';
import '../models/enrollment_model.dart';
import '../../core/utils/rank_sorter.dart';
import 'package:flutter/foundation.dart';

class EnrollmentRepositoryImpl implements EnrollmentRepository {
  final DatabaseHelper dbHelper;

  EnrollmentRepositoryImpl({required this.dbHelper});

  @override
  Future<List<Enrollment>> getEnrollmentsByGroup(String groupId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT e.*, u.name as student_name, g.name as group_name,
             s.grade, s.specialty, s.graduation_year, s.course_seniority
      FROM enrollments e
      INNER JOIN users u ON e.student_id = u.id
      INNER JOIN groups g ON e.group_id = g.id
      LEFT JOIN students s ON s.user_id = u.id
      WHERE e.group_id = ?
    ''',
      [groupId],
    );

    final enrollments = List.generate(
      maps.length,
      (i) => EnrollmentModel.fromMap(maps[i]),
    );
    return RankSorter.sortEnrollments(enrollments);
  }

  @override
  Future<void> enrollStudent(Enrollment enrollment) async {
    final db = await dbHelper.database;
    await db.insert(
      'enrollments',
      EnrollmentModel.fromEntity(enrollment).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> removeStudent(String id) async {
    final db = await dbHelper.database;
    await db.delete('enrollments', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<Enrollment>> getEnrollmentsByStudent(String studentId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT e.*, u.name as student_name, g.name as group_name, c.name as course_name, 
             cb.id as bundle_id, cb.name as bundle_name, cb.academic_year
      FROM enrollments e
      INNER JOIN users u ON e.student_id = u.id
      INNER JOIN groups g ON e.group_id = g.id
      INNER JOIN courses c ON g.course_id = c.id
      LEFT JOIN course_bundles cb ON g.bundle_id = cb.id
      WHERE e.student_id = ?
    ''',
      [studentId],
    );

    return List.generate(maps.length, (i) => EnrollmentModel.fromMap(maps[i]));
  }

  @override
  Future<List<Enrollment>> getEnrollmentsByBundle(String bundleId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT e.*, u.name as student_name, g.name as group_name, c.name as course_name,
             cb.id as bundle_id, cb.name as bundle_name, cb.academic_year,
             s.grade, s.specialty, s.graduation_year, s.course_seniority
      FROM enrollments e
      INNER JOIN users u ON e.student_id = u.id
      INNER JOIN groups g ON e.group_id = g.id
      INNER JOIN courses c ON g.course_id = c.id
      LEFT JOIN course_bundles cb ON g.bundle_id = cb.id
      LEFT JOIN students s ON s.user_id = u.id
      WHERE g.bundle_id = ?
    ''',
      [bundleId],
    );

    final enrollments = List.generate(
      maps.length,
      (i) => EnrollmentModel.fromMap(maps[i]),
    );
    return RankSorter.sortEnrollments(enrollments);
  }

  @override
  Future<bool> isStudentEnrolledInYear(String studentId, int year) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''
      SELECT COUNT(*) 
      FROM enrollments e
      JOIN groups g ON e.group_id = g.id
      JOIN course_bundles cb ON g.bundle_id = cb.id
      WHERE e.student_id = ? AND cb.academic_year = ?
    ''',
      [studentId, year],
    );

    return (Sqflite.firstIntValue(result) ?? 0) > 0;
  }

  @override
  Future<void> removeStudentFromBundle(
    String studentId,
    String bundleId,
  ) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      // Find all groups in this bundle
      final List<Map<String, dynamic>> groups = await txn.query(
        'groups',
        columns: ['id'],
        where: 'bundle_id = ?',
        whereArgs: [bundleId],
      );

      final List<String> groupIds = groups
          .map((g) => g['id'] as String)
          .toList();

      if (groupIds.isNotEmpty) {
        // Delete enrollments for these groups for this student
        await txn.delete(
          'enrollments',
          where:
              'student_id = ? AND group_id IN (${groupIds.map((_) => '?').join(',')})',
          whereArgs: [studentId, ...groupIds],
        );
      }
    });
  }

  @override
  Future<int?> getBundleYear(String bundleId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'course_bundles',
      columns: ['academic_year'],
      where: 'id = ?',
      whereArgs: [bundleId],
    );

    if (maps.isNotEmpty) {
      return maps.first['academic_year'] as int?;
    }
    return null;
  }

  @override
  Future<void> updateEnrollmentStatus(
    String enrollmentId,
    String status,
  ) async {
    final db = await dbHelper.database;
    await db.update(
      'enrollments',
      {'status': status},
      where: 'id = ?',
      whereArgs: [enrollmentId],
    );
  }

  @override
  Future<void> updateStudentStatusByBundle(
    String studentId,
    String bundleId,
    String status,
  ) async {
    final db = await dbHelper.database;
    final count = await db.rawUpdate(
      '''
      UPDATE enrollments 
      SET status = ? 
      WHERE student_id = ? 
      AND group_id IN (SELECT id FROM groups WHERE bundle_id = ?)
    ''',
      [status, studentId, bundleId],
    );
    debugPrint("Updated student status: $count enrollments affected.");
  }
}
