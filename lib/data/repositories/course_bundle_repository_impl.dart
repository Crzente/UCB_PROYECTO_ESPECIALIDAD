import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../domain/entities/course_bundle.dart';
import '../../domain/repositories/course_bundle_repository.dart';
import '../models/course_bundle_model.dart';

class CourseBundleRepositoryImpl implements CourseBundleRepository {
  final DatabaseHelper dbHelper;

  CourseBundleRepositoryImpl({required this.dbHelper});

  @override
  Future<List<CourseBundle>> getAllBundles() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'course_bundles',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'academic_year DESC, name ASC',
    );
    return List.generate(
      maps.length,
      (i) => CourseBundleModel.fromMap(maps[i]),
    );
  }

  @override
  Future<void> createBundle(CourseBundle bundle) async {
    final db = await dbHelper.database;
    await db.insert(
      'course_bundles',
      CourseBundleModel.fromEntity(bundle).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<bool> canDeleteBundle(String id) async {
    final db = await dbHelper.database;

    // Check if there are any groups in this bundle that are active
    final activeGroups = await db.rawQuery(
      '''
      SELECT COUNT(*) FROM groups WHERE bundle_id = ? AND status = 'active'
    ''',
      [id],
    );
    if ((Sqflite.firstIntValue(activeGroups) ?? 0) > 0) return false;

    // Check if there are any enrollments in any group of this bundle
    final enrollments = await db.rawQuery(
      '''
      SELECT COUNT(*) FROM enrollments e
      JOIN groups g ON e.group_id = g.id
      WHERE g.bundle_id = ?
    ''',
      [id],
    );
    if ((Sqflite.firstIntValue(enrollments) ?? 0) > 0) return false;

    return true;
  }

  @override
  Future<void> deleteBundle(String id) async {
    final db = await dbHelper.database;
    if (!(await canDeleteBundle(id))) {
      throw Exception(
        'No se puede eliminar el curso ya que tiene materias activas o alumnos con registros. Debe archivar o retirar las materias primero.',
      );
    }

    await db.transaction((txn) async {
      // First delete associated groups/subjects (if any left/archived)
      await txn.delete('groups', where: 'bundle_id = ?', whereArgs: [id]);
      // Then delete the bundle
      await txn.delete('course_bundles', where: 'id = ?', whereArgs: [id]);
    });
  }

  @override
  Future<CourseBundle?> getBundleById(String id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'course_bundles',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return CourseBundleModel.fromMap(maps.first);
    }
    return null;
  }
}
