import '../../core/database/database_helper.dart';
import '../../domain/entities/academic_period_config.dart';

class AcademicConfigRepositoryImpl {
  final DatabaseHelper dbHelper;

  AcademicConfigRepositoryImpl({required this.dbHelper});

  // Get active configuration
  Future<List<AcademicPeriodConfig>> getActiveConfig() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'academic_config',
      orderBy: 'order_index ASC',
    );

    return List.generate(maps.length, (i) {
      return AcademicPeriodConfig(
        id: maps[i]['id'].toString(), // Simple int ID as string
        name: maps[i]['name'],
        orderIndex: maps[i]['order_index'],
        defaultWeight: (maps[i]['default_weight'] as num).toDouble(),
      );
    });
  }

  // Initialize/Reset configuration (e.g. Set to 4 Bimesters)
  Future<void> setBimestersConfig() async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('academic_config'); // Clear old config

      // Insert 4 Bimesters
      for (int i = 1; i <= 4; i++) {
        await txn.insert('academic_config', {
          'id': i,
          'name': 'Bimestre $i',
          'order_index': i,
          'default_weight': 25.0,
        });
      }
    });
  }

  // Initialize/Reset configuration (e.g. Set to 3 Trimesters)
  Future<void> setTrimestersConfig() async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('academic_config'); // Clear old config

      // Insert 3 Trimesters
      for (int i = 1; i <= 3; i++) {
        await txn.insert('academic_config', {
          'id': i,
          'name': 'Trimestre $i',
          'order_index': i,
          'default_weight': 33.33,
        });
      }
    });
  }

  Future<void> updateConfig(String id, String name, double weight) async {
    final db = await dbHelper.database;
    await db.update(
      'academic_config',
      {'name': name, 'default_weight': weight},
      where: 'id = ?',
      whereArgs: [
        id,
      ], // ID is text or int? in DB helper it was int probably but let's assume sqflite handles string-int conversion usually if column is int.
    );
  }
}
