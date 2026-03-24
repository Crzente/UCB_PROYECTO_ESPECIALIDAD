import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../domain/entities/grade.dart';
import '../../domain/repositories/grade_repository.dart';
import '../models/grade_model.dart';

class GradeRepositoryImpl implements GradeRepository {
  final DatabaseHelper dbHelper;

  GradeRepositoryImpl({required this.dbHelper});

  @override
  Future<List<Grade>> getGradesByGroup(String groupId) async {
    final db = await dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT g.* 
      FROM grades g
      INNER JOIN enrollments e ON g.enrollment_id = e.id
      WHERE e.group_id = ?
    ''',
      [groupId],
    );

    return List.generate(maps.length, (i) => GradeModel.fromMap(maps[i]));
  }

  @override
  Future<List<Grade>> getGradesByBundle(String bundleId) async {
    final db = await dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT g.* 
      FROM grades g
      INNER JOIN enrollments e ON g.enrollment_id = e.id
      INNER JOIN groups gr ON e.group_id = gr.id
      WHERE gr.bundle_id = ?
    ''',
      [bundleId],
    );

    return List.generate(maps.length, (i) => GradeModel.fromMap(maps[i]));
  }

  @override
  Future<void> saveGrade(Grade grade) async {
    final db = await dbHelper.database;

    // Semantic key check to avoid duplicates in case of ID mismatch between layers
    final List<Map<String, dynamic>> existing = await db.query(
      'grades',
      where: 'enrollment_id = ? AND evaluation_period_id = ?',
      whereArgs: [grade.enrollmentId, grade.evaluationPeriodId],
    );

    if (existing.isNotEmpty) {
      // Update the existing record regardless of the ID passed from UI
      final String existingId = existing.first['id'];
      await db.update(
        'grades',
        GradeModel.fromEntity(grade).toMap()..['id'] = existingId,
        where: 'id = ?',
        whereArgs: [existingId],
      );
    } else {
      // Safe insert
      await db.insert(
        'grades',
        GradeModel.fromEntity(grade).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}
