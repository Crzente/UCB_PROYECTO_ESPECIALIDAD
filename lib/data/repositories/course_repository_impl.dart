import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/database_helper.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/evaluation_template.dart';
import '../../domain/repositories/course_repository.dart';
import '../models/course_model.dart';

class CourseRepositoryImpl implements CourseRepository {
  final DatabaseHelper dbHelper;
  final _uuid = const Uuid();

  CourseRepositoryImpl({required this.dbHelper});

  @override
  Future<List<Course>> getAllCourses() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('courses');
    return List.generate(maps.length, (i) => CourseModel.fromMap(maps[i]));
  }

  @override
  Future<void> createCourse(Course course) async {
    final db = await dbHelper.database;
    await db.insert(
      'courses',
      CourseModel.fromEntity(course).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateCourse(Course course) async {
    final db = await dbHelper.database;
    await db.update(
      'courses',
      CourseModel.fromEntity(course).toMap(),
      where: 'id = ?',
      whereArgs: [course.id],
    );
  }

  @override
  Future<bool> canDeleteCourse(String id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''
      SELECT COUNT(*) as active_count 
      FROM groups 
      WHERE course_id = ? AND status = 'active'
    ''',
      [id],
    );

    final int activeCount = Sqflite.firstIntValue(result) ?? 0;
    return activeCount == 0;
  }

  @override
  Future<void> deleteCourse(String id) async {
    final db = await dbHelper.database;
    if (await canDeleteCourse(id)) {
      await db.delete('courses', where: 'id = ?', whereArgs: [id]);
    } else {
      throw Exception(
        'Esta materia aún tiene cursos activos. No se puede eliminar hasta que se eliminen todos los cursos asociados.',
      );
    }
  }

  // --- Templates ---

  @override
  Future<List<EvaluationTemplate>> getEvaluationTemplates(
    String courseId,
  ) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'course_evaluation_templates',
      where: 'course_id = ?',
      whereArgs: [courseId],
    );
    return result.map((m) => EvaluationTemplate.fromMap(m)).toList();
  }

  @override
  Future<void> addEvaluationTemplate(
    String courseId,
    String name,
    double weight,
  ) async {
    final db = await dbHelper.database;
    final id = _uuid.v4();
    await db.insert('course_evaluation_templates', {
      'id': id,
      'course_id': courseId,
      'name': name,
      'weight': weight,
    });
  }

  @override
  Future<void> deleteEvaluationTemplate(String templateId) async {
    final db = await dbHelper.database;
    await db.delete(
      'course_evaluation_templates',
      where: 'id = ?',
      whereArgs: [templateId],
    );
  }

  @override
  Future<void> updateEvaluationTemplate(
    String templateId,
    String name,
    double weight,
  ) async {
    final db = await dbHelper.database;
    await db.update(
      'course_evaluation_templates',
      {'name': name, 'weight': weight},
      where: 'id = ?',
      whereArgs: [templateId],
    );
  }
}
