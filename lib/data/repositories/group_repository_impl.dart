import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../domain/entities/group.dart';
import '../../domain/repositories/group_repository.dart';
import '../models/group_model.dart';

class GroupRepositoryImpl implements GroupRepository {
  final DatabaseHelper dbHelper;

  GroupRepositoryImpl({required this.dbHelper});

  @override
  Future<List<Group>> getAllGroups() async {
    final db = await dbHelper.database;
    // Perform LEFT JOIN to get course name and teacher name
    // Using LEFT JOIN ensures results appear even if name joins fail
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT g.*, c.name as course_name, u.name as teacher_name,
             (SELECT COUNT(*) FROM enrollments e WHERE e.group_id = g.id) as student_count
      FROM groups g
      LEFT JOIN courses c ON g.course_id = c.id
      LEFT JOIN users u ON g.teacher_id = u.id
    ''');

    final groups = List.generate(
      maps.length,
      (i) => GroupModel.fromMap(maps[i]),
    );
    debugPrint("Repo: Loaded ${groups.length} total groups from DB");
    return groups;
  }

  @override
  Future<List<Group>> getGroupsByCourse(String courseId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT g.*, c.name as course_name, u.name as teacher_name,
             (SELECT COUNT(*) FROM enrollments e WHERE e.group_id = g.id) as student_count
      FROM groups g
      INNER JOIN courses c ON g.course_id = c.id
      INNER JOIN users u ON g.teacher_id = u.id
      WHERE g.course_id = ?
    ''',
      [courseId],
    );

    return List.generate(maps.length, (i) => GroupModel.fromMap(maps[i]));
  }

  @override
  Future<List<String>> getUniqueGroupNames() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT DISTINCT name FROM groups ORDER BY name
    ''');
    return result.map((row) => row['name'] as String).toList();
  }

  // Helper for enrollment logic (not in interface but useful)
  Future<List<Group>> getGroupsByName(String name) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT g.*, c.name as course_name, u.name as teacher_name,
             (SELECT COUNT(*) FROM enrollments e WHERE e.group_id = g.id) as student_count
      FROM groups g
      INNER JOIN courses c ON g.course_id = c.id
      INNER JOIN users u ON g.teacher_id = u.id
      WHERE g.name = ?
    ''',
      [name],
    );

    return List.generate(maps.length, (i) => GroupModel.fromMap(maps[i]));
  }

  @override
  Future<void> createGroup(Group group) async {
    final db = await dbHelper.database;
    final map = GroupModel.fromEntity(group).toMap();
    debugPrint("Repo: Saving group to DB: $map");
    await db.insert(
      'groups',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint("Repo: Group saved successfully.");
  }

  @override
  Future<void> updateGroup(Group group) async {
    final db = await dbHelper.database;
    final map = GroupModel.fromEntity(group).toMap();
    await db.update('groups', map, where: 'id = ?', whereArgs: [group.id]);
  }

  @override
  Future<bool> canDeleteGroup(String id) async {
    final db = await dbHelper.database;

    // Check if there are any non-null grades recorded for this group
    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''
      SELECT COUNT(*) as grade_count
      FROM grades g
      INNER JOIN enrollments e ON g.enrollment_id = e.id
      WHERE e.group_id = ? AND g.score IS NOT NULL
    ''',
      [id],
    );

    if (result.isEmpty) return true;

    final int gradeCount = result.first['grade_count'] as int;

    // Can delete if there are no real grades recorded
    return gradeCount == 0;
  }

  @override
  Future<void> deleteGroup(String id) async {
    final db = await dbHelper.database;
    if (await canDeleteGroup(id)) {
      // Delete in transaction: grades → enrollments → group
      await db.transaction((txn) async {
        // Delete grades for enrollments in this group
        await txn.rawDelete(
          'DELETE FROM grades WHERE enrollment_id IN (SELECT id FROM enrollments WHERE group_id = ?)',
          [id],
        );
        // Delete evaluation periods for this group
        await txn.delete(
          'evaluation_periods',
          where: 'group_id = ?',
          whereArgs: [id],
        );
        // Delete enrollments for this group
        await txn.delete(
          'enrollments',
          where: 'group_id = ?',
          whereArgs: [id],
        );
        // Finally delete the group
        await txn.delete('groups', where: 'id = ?', whereArgs: [id]);
      });
    } else {
      throw Exception(
        'No se puede eliminar esta materia porque ya tiene notas registradas. Debe archivar el curso.',
      );
    }
  }
}
