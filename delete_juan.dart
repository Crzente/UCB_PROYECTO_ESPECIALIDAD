import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

void main() async {
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;
  
  var dbPath = await databaseFactory.getDatabasesPath();
  var path = p.join(dbPath, 'school_management.db');
  
  var db = await databaseFactory.openDatabase(path);
  
  var result = await db.query('users', where: 'name LIKE ?', whereArgs: ['%Juan Perez%']);
  print('Users found matching Juan Perez: ' + result.toString());
  
  int deleted = 0;
  for (var u in result) {
    int count = await db.delete('users', where: 'id = ?', whereArgs: [u['id']]);
    deleted += count;
  }
  
  print('Deleted ' + deleted.toString() + ' user(s). Cascade should have handled students and enrollments.');
  
  await db.close();
}
