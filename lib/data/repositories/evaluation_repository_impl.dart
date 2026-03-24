import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../domain/entities/evaluation_period.dart';
import '../../domain/repositories/evaluation_repository.dart';
import '../models/evaluation_period_model.dart';

class EvaluationRepositoryImpl implements EvaluationRepository {
  final DatabaseHelper dbHelper;

  EvaluationRepositoryImpl({required this.dbHelper});

  @override
  Future<List<EvaluationPeriod>> getPeriodsByGroup(String groupId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'evaluation_periods',
      where: 'group_id = ?',
      whereArgs: [groupId],
    );
    return List.generate(
      maps.length,
      (i) => EvaluationPeriodModel.fromMap(maps[i]),
    );
  }

  @override
  Future<List<EvaluationPeriod>> getPeriodsByBundle(String bundleId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT ep.* 
      FROM evaluation_periods ep
      INNER JOIN groups g ON ep.group_id = g.id
      WHERE g.bundle_id = ?
    ''',
      [bundleId],
    );
    return List.generate(
      maps.length,
      (i) => EvaluationPeriodModel.fromMap(maps[i]),
    );
  }

  @override
  Future<void> addPeriod(EvaluationPeriod period) async {
    final db = await dbHelper.database;
    await db.insert(
      'evaluation_periods',
      EvaluationPeriodModel.fromEntity(period).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updatePeriod(EvaluationPeriod period) async {
    final db = await dbHelper.database;
    await db.update(
      'evaluation_periods',
      EvaluationPeriodModel.fromEntity(period).toMap(),
      where: 'id = ?',
      whereArgs: [period.id],
    );
  }

  @override
  Future<void> deletePeriod(String id) async {
    final db = await dbHelper.database;
    await db.delete('evaluation_periods', where: 'id = ?', whereArgs: [id]);
  }
}
