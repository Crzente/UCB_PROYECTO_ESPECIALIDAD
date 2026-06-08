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

    // 1. Enrollments via materias (grupos)
    final List<Map<String, dynamic>> materialMaps = await db.rawQuery(
      '''
      SELECT e.id, e.student_id, e.group_id, e.status,
             u.name as student_name, g.name as group_name, c.name as course_name,
             cb.id as bundle_id, cb.name as bundle_name, cb.academic_year,
             NULL as grade, NULL as specialty, NULL as graduation_year, NULL as course_seniority
      FROM enrollments e
      INNER JOIN users u ON e.student_id = u.id
      INNER JOIN groups g ON e.group_id = g.id
      INNER JOIN courses c ON g.course_id = c.id
      LEFT JOIN course_bundles cb ON g.bundle_id = cb.id
      WHERE e.student_id = ?
    ''',
      [studentId],
    );

    // 2. Bundle-level enrollments (cursos sin materias todavía)
    // Solo incluir bundles que NO tienen grupos con inscripciones ya incluidos arriba
    final List<Map<String, dynamic>> bundleMaps = await db.rawQuery(
      '''
      SELECT be.id, be.student_id, be.bundle_id as group_id, be.status,
             u.name as student_name, cb.name as group_name, '' as course_name,
             cb.id as bundle_id, cb.name as bundle_name, cb.academic_year,
             NULL as grade, NULL as specialty, NULL as graduation_year, NULL as course_seniority
      FROM bundle_enrollments be
      INNER JOIN users u ON be.student_id = u.id
      INNER JOIN course_bundles cb ON be.bundle_id = cb.id
      WHERE be.student_id = ?
        AND NOT EXISTS (
          SELECT 1 FROM enrollments e2
          INNER JOIN groups g2 ON e2.group_id = g2.id
          WHERE e2.student_id = be.student_id AND g2.bundle_id = be.bundle_id
        )
    ''',
      [studentId],
    );

    final allMaps = [...materialMaps, ...bundleMaps];
    return List.generate(allMaps.length, (i) => EnrollmentModel.fromMap(allMaps[i]));
  }

  @override
  Future<List<Enrollment>> getEnrollmentsByBundle(String bundleId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT be.id, be.student_id, be.bundle_id as group_id, be.status,
             u.name as student_name, cb.name as group_name, '' as course_name,
             cb.id as bundle_id, cb.name as bundle_name, cb.academic_year,
             s.grade, s.specialty, s.graduation_year, s.course_seniority
      FROM bundle_enrollments be
      INNER JOIN users u ON be.student_id = u.id
      INNER JOIN course_bundles cb ON be.bundle_id = cb.id
      LEFT JOIN students s ON s.user_id = u.id
      WHERE be.bundle_id = ?
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
      FROM bundle_enrollments be
      JOIN course_bundles cb ON be.bundle_id = cb.id
      WHERE be.student_id = ? AND cb.academic_year = ?
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
      // First, remove from bundle_enrollments
      await txn.delete(
        'bundle_enrollments',
        where: 'student_id = ? AND bundle_id = ?',
        whereArgs: [studentId, bundleId],
      );

      // Then, find all groups in this bundle
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
    await db.transaction((txn) async {
      // Update in bundle_enrollments
      await txn.rawUpdate(
        '''
        UPDATE bundle_enrollments 
        SET status = ? 
        WHERE student_id = ? AND bundle_id = ?
      ''',
        [status, studentId, bundleId],
      );

      // Update in individual group enrollments
      final count = await txn.rawUpdate(
        '''
        UPDATE enrollments 
        SET status = ? 
        WHERE student_id = ? 
        AND group_id IN (SELECT id FROM groups WHERE bundle_id = ?)
      ''',
        [status, studentId, bundleId],
      );
      debugPrint("Updated student status: $count enrollments affected.");
    });
  }

  @override
  Future<void> addStudentToBundle(String studentId, String bundleId) async {
    final db = await dbHelper.database;
    // Generate UUID string representation since uuid package might not be immediately available here safely
    final idList = await db.rawQuery('SELECT lower(hex(randomblob(16))) as id');
    final String uuid = idList.first['id'] as String;

    await db.insert(
      'bundle_enrollments',
      {
        'id': uuid,
        'bundle_id': bundleId,
        'student_id': studentId,
        'status': 'En curso',
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
