import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

void main() async {
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;
  
  var dbPath = await databaseFactory.getDatabasesPath();
  var path = p.join(dbPath, 'school_management.db');
  
  var db = await databaseFactory.openDatabase(path);
  
  var result = await db.query('users');
  for(var u in result) {
    print(u['id'].toString() + " - " + u['name'].toString());
  }
  
  await db.close();
}
