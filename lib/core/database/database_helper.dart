import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('school_management.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 23, // Incremented to 23 to support bundle_enrollments
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    
    // TEMPORARY: Delete Juan Perez based on user request
    try {
      await db.delete('users', where: 'name LIKE ?', whereArgs: ['%Juan Perez%']);
    } catch (_) {}
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Users Table (Personas / Cuentas)
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        profile_image TEXT
      )
    ''');

    // 2. Students Table (Perfiles Académicos Alumno)
    await db.execute('''
      CREATE TABLE students (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        student_code TEXT,
        status TEXT NOT NULL DEFAULT 'active',
        birth_date TEXT,
        identity_card TEXT,
        military_card TEXT,
        insurance_card TEXT,
        phone TEXT,
        grade TEXT,
        specialty TEXT,
        graduation_year TEXT,
        profile_image TEXT,
        course_seniority INTEGER,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // 3. Teachers Table (Perfiles Académicos Docente)
    await db.execute('''
      CREATE TABLE teachers (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        teacher_code TEXT,
        status TEXT NOT NULL DEFAULT 'active',
        birth_date TEXT,
        identity_card TEXT,
        military_card TEXT,
        insurance_card TEXT,
        phone TEXT,
        grade TEXT,
        specialty TEXT,
        graduation_year TEXT,
        profile_image TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // 4. Courses Table (Materias base / Plantillas)
    // Updated for v12 fields
    await db.execute('''
      CREATE TABLE courses (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        code TEXT,
        credits INTEGER,
        type TEXT DEFAULT 'mixed',
        is_mandatory INTEGER DEFAULT 1,
        teacher_id TEXT,
        FOREIGN KEY (teacher_id) REFERENCES teachers (id) ON DELETE SET NULL
      )
    ''');

    // 5. Groups Table (Instancias de Materias por Periodo/Año)
    await db.execute('''
      CREATE TABLE groups (
        id TEXT PRIMARY KEY,
        course_id TEXT NOT NULL,
        teacher_id TEXT NOT NULL,
        year INTEGER NOT NULL,
        name TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        bundle_id TEXT,
        FOREIGN KEY (course_id) REFERENCES courses (id) ON DELETE CASCADE,
        FOREIGN KEY (bundle_id) REFERENCES course_bundles(id) ON DELETE SET NULL
      )
    ''');

    // 6. Enrollments Table
    await db.execute('''
      CREATE TABLE enrollments (
        id TEXT PRIMARY KEY,
        student_id TEXT NOT NULL,
        group_id TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'En curso',
        FOREIGN KEY (student_id) REFERENCES users (id) ON DELETE CASCADE, 
        FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE
      )
    ''');

    // 7. Grades Table
    await db.execute('''
      CREATE TABLE grades (
        id TEXT PRIMARY KEY,
        enrollment_id TEXT NOT NULL,
        evaluation_period_id TEXT NOT NULL,
        score REAL,
        FOREIGN KEY (enrollment_id) REFERENCES enrollments (id) ON DELETE CASCADE,
        FOREIGN KEY (evaluation_period_id) REFERENCES evaluation_periods (id) ON DELETE CASCADE
      )
    ''');

    // 8. Evaluation Periods
    await db.execute('''
      CREATE TABLE evaluation_periods (
        id TEXT PRIMARY KEY,
        group_id TEXT NOT NULL,
        name TEXT NOT NULL,
        weight REAL NOT NULL,
        FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE
      )
    ''');

    // 9. Academic Config
    await db.execute('''
      CREATE TABLE academic_config (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        order_index INTEGER NOT NULL,
        default_weight REAL NOT NULL
      )
    ''');

    // 10. Final Grades History
    await db.execute('''
      CREATE TABLE final_grades_history (
        id TEXT PRIMARY KEY,
        student_id TEXT NOT NULL,
        student_name TEXT NOT NULL,
        course_id TEXT NOT NULL,
        course_name TEXT NOT NULL,
        group_id TEXT NOT NULL,
        group_name TEXT NOT NULL,
        year INTEGER NOT NULL,
        final_score REAL NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 11. Reports
    await db.execute('''
      CREATE TABLE academic_year_reports (
        id TEXT PRIMARY KEY,
        year INTEGER NOT NULL UNIQUE,
        generated_at TEXT NOT NULL,
        total_students INTEGER NOT NULL,
        total_courses INTEGER NOT NULL,
        total_groups INTEGER NOT NULL,
        report_data TEXT
      )
    ''');

    // 12. Course Evaluation Templates (New in v11)
    await db.execute('''
      CREATE TABLE course_evaluation_templates (
        id TEXT PRIMARY KEY,
        course_id TEXT NOT NULL,
        name TEXT NOT NULL,
        weight REAL NOT NULL,
        FOREIGN KEY (course_id) REFERENCES courses (id) ON DELETE CASCADE
      )
    ''');

    // 13. Course Bundles (New in v13)
    await db.execute('''
      CREATE TABLE course_bundles (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        academic_year INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        is_active INTEGER DEFAULT 1
      )
    ''');

    // 14. Bundle Enrollments
    await db.execute('''
      CREATE TABLE bundle_enrollments (
        id TEXT PRIMARY KEY,
        bundle_id TEXT NOT NULL,
        student_id TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'En curso',
        created_at TEXT NOT NULL,
        FOREIGN KEY (bundle_id) REFERENCES course_bundles (id) ON DELETE CASCADE,
        FOREIGN KEY (student_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    // Config
    await db.insert('academic_config', {
      'id': 1,
      'name': 'Bimestre 1',
      'order_index': 1,
      'default_weight': 25.0,
    });
    await db.insert('academic_config', {
      'id': 2,
      'name': 'Bimestre 2',
      'order_index': 2,
      'default_weight': 25.0,
    });
    await db.insert('academic_config', {
      'id': 3,
      'name': 'Bimestre 3',
      'order_index': 3,
      'default_weight': 25.0,
    });
    await db.insert('academic_config', {
      'id': 4,
      'name': 'Bimestre 4',
      'order_index': 4,
      'default_weight': 25.0,
    });

    // Admin User
    await db.insert('users', {
      'id': 'admin_001',
      'email': 'admin',
      'password': 'admin',
      'name': 'Super Administrador',
      'role': 'admin',
      'status': 'active',
    });
  }

  Future<void> repairAdminUser() async {
    final db = await database;
    // Check if user 'admin' exists and has role 'admin'
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: ['admin'],
    );

    if (maps.isNotEmpty) {
      final user = maps.first;
      if (user['role'] != 'admin') {
        debugPrint("Repairing admin user role to 'admin'...");
        await db.update(
          'users',
          {'role': 'admin'},
          where: 'email = ?',
          whereArgs: ['admin'],
        );
      }
    } else {
      debugPrint("Admin user not found, recreating...");
      await db.insert('users', {
        'id': 'admin_001',
        'email': 'admin',
        'password': 'admin',
        'name': 'Super Administrador',
        'role': 'admin',
        'status': 'active',
      });
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Cumulative migrations
    if (oldVersion < 9) {
      // Logic from previous versions if we wanted to support them,
      // but since we are refactoring, we focus on < 10.
    }

    if (oldVersion < 10) {
      // 1. Add status to users
      try {
        await db.execute(
          "ALTER TABLE users ADD COLUMN status TEXT DEFAULT 'active'",
        );
      } catch (_) {}

      // 2. Create Students Table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS students (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          student_code TEXT,
          status TEXT NOT NULL DEFAULT 'active',
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');

      // 3. Create Teachers Table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS teachers (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          teacher_code TEXT,
          status TEXT NOT NULL DEFAULT 'active',
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');

      // 4. Migration: Populate Students and Teachers from Users Role
      // We use the User ID as the Student/Teacher ID to maintain relation simplicity for now
      final List<Map<String, dynamic>> users = await db.query('users');
      for (var user in users) {
        final String role = user['role'] as String;
        final String id = user['id'] as String;

        if (role == 'student') {
          final exists = await db.query(
            'students',
            where: 'id = ?',
            whereArgs: [id],
          );
          if (exists.isEmpty) {
            await db.insert('students', {
              'id': id,
              'user_id': id,
              'student_code': 'S-$id',
              'status': 'active',
            });
          }
        } else if (role == 'teacher') {
          final exists = await db.query(
            'teachers',
            where: 'id = ?',
            whereArgs: [id],
          );
          if (exists.isEmpty) {
            await db.insert('teachers', {
              'id': id,
              'user_id': id,
              'teacher_code': 'T-$id',
              'status': 'active',
            });
          }
        }
      }
    }

    if (oldVersion < 11) {
      // Create Course Evaluation Templates Table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS course_evaluation_templates (
          id TEXT PRIMARY KEY,
          course_id TEXT NOT NULL,
          name TEXT NOT NULL,
          weight REAL NOT NULL,
          FOREIGN KEY (course_id) REFERENCES courses (id) ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 12) {
      // Add columns to courses table
      try {
        await db.execute("ALTER TABLE courses ADD COLUMN code TEXT");
        await db.execute("ALTER TABLE courses ADD COLUMN credits INTEGER");
        await db.execute(
          "ALTER TABLE courses ADD COLUMN type TEXT DEFAULT 'mixed'",
        );
        await db.execute(
          "ALTER TABLE courses ADD COLUMN is_mandatory INTEGER DEFAULT 1",
        );
        await db.execute("ALTER TABLE courses ADD COLUMN teacher_id TEXT");
      } catch (_) {
        // Ignore if columns already exist (safe migration)
      }
    }

    if (oldVersion < 13) {
      // 1. Create Course Bundles Table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS course_bundles (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          academic_year INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          is_active INTEGER DEFAULT 1
        )
      ''');

      // 2. Add bundle_id to groups
      try {
        await db.execute(
          "ALTER TABLE groups ADD COLUMN bundle_id TEXT REFERENCES course_bundles(id) ON DELETE SET NULL",
        );
      } catch (_) {}

      // 3. Populate course_bundles from existing groups (Migration Logic)
      // Extract unique (name, year) pairs from groups
      final List<Map<String, dynamic>> groups = await db.query('groups');
      final Map<String, String> bundleMap = {}; // key -> bundleId
      final uuid = const Uuid();

      for (var group in groups) {
        final String name = group['name'];
        final int year = group['year'];
        final String key = "$name-$year";

        if (!bundleMap.containsKey(key)) {
          final bundleId = uuid.v4();
          bundleMap[key] = bundleId;

          await db.insert('course_bundles', {
            'id': bundleId,
            'name': name,
            'academic_year': year,
            'created_at': DateTime.now().toIso8601String(),
            'is_active': 1,
          });
        }
      }

      // 4. Update groups with bundle_id
      for (var group in groups) {
        final String id = group['id'];
        final String name = group['name'];
        final int year = group['year'];
        final String key = "$name-$year";

        if (bundleMap.containsKey(key)) {
          await db.update(
            'groups',
            {'bundle_id': bundleMap[key]},
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      }
    }
    if (oldVersion < 14) {
      // Add profile columns to students table
      await db.execute("ALTER TABLE students ADD COLUMN birth_date TEXT");
      await db.execute("ALTER TABLE students ADD COLUMN identity_card TEXT");
      await db.execute("ALTER TABLE students ADD COLUMN military_card TEXT");
      await db.execute("ALTER TABLE students ADD COLUMN insurance_card TEXT");
      await db.execute("ALTER TABLE students ADD COLUMN phone TEXT");
      await db.execute("ALTER TABLE students ADD COLUMN grade TEXT");
      await db.execute("ALTER TABLE students ADD COLUMN specialty TEXT");
      await db.execute("ALTER TABLE students ADD COLUMN graduation_year TEXT");
    }

    if (oldVersion < 15) {
      // Robust check for version 15 to fix partially failed migrations from 14
      final tableInfo = await db.rawQuery("PRAGMA table_info(students)");
      final columns = tableInfo.map((c) => c['name'] as String).toList();

      final requiredColumns = {
        'birth_date': 'TEXT',
        'identity_card': 'TEXT',
        'military_card': 'TEXT',
        'insurance_card': 'TEXT',
        'phone': 'TEXT',
        'grade': 'TEXT',
        'specialty': 'TEXT',
        'graduation_year': 'TEXT',
      };

      for (var entry in requiredColumns.entries) {
        if (!columns.contains(entry.key)) {
          debugPrint("Adding missing column ${entry.key} to students table...");
          await db.execute(
            "ALTER TABLE students ADD COLUMN ${entry.key} ${entry.value}",
          );
        }
      }
    }

    if (oldVersion < 16) {
      final tableInfo = await db.rawQuery("PRAGMA table_info(students)");
      final columns = tableInfo.map((c) => c['name'] as String).toList();
      if (!columns.contains('profile_image')) {
        await db.execute("ALTER TABLE students ADD COLUMN profile_image TEXT");
      }
    }

    if (oldVersion < 17) {
      // Add profile fields to teachers table
      // We check existing columns just in case to be safe, though strict versioning should handle it.
      // But adding columns is safe with try-catch in case they exist or checking manually.
      // Let's use simple try-catch block for bulk addition or check PRAGMA if we want robustness.
      // Given the style above, i will use try catch or simple execute sequence.
      try {
        await db.execute("ALTER TABLE teachers ADD COLUMN birth_date TEXT");
        await db.execute("ALTER TABLE teachers ADD COLUMN identity_card TEXT");
        await db.execute("ALTER TABLE teachers ADD COLUMN military_card TEXT");
        await db.execute("ALTER TABLE teachers ADD COLUMN insurance_card TEXT");
        await db.execute("ALTER TABLE teachers ADD COLUMN phone TEXT");
        await db.execute("ALTER TABLE teachers ADD COLUMN grade TEXT");
        await db.execute("ALTER TABLE teachers ADD COLUMN specialty TEXT");
        await db.execute(
          "ALTER TABLE teachers ADD COLUMN graduation_year TEXT",
        );
        await db.execute("ALTER TABLE teachers ADD COLUMN profile_image TEXT");
      } catch (_) {}
    }

    if (oldVersion < 19) {
      // Robust check for course_seniority column in students table
      final tableInfo = await db.rawQuery("PRAGMA table_info(students)");
      final columns = tableInfo.map((c) => c['name'] as String).toList();

      if (!columns.contains('course_seniority')) {
        debugPrint(
          "Adding missing column course_seniority to students table...",
        );
        await db.execute(
          "ALTER TABLE students ADD COLUMN course_seniority INTEGER",
        );
      }
    }

    if (oldVersion < 20) {
      final tableInfo = await db.rawQuery("PRAGMA table_info(enrollments)");
      final columns = tableInfo.map((c) => c['name'] as String).toList();

      if (!columns.contains('status')) {
        debugPrint("Adding missing column status to enrollments table...");
        await db.execute(
          "ALTER TABLE enrollments ADD COLUMN status TEXT NOT NULL DEFAULT 'En curso'",
        );
      }
    }

    if (oldVersion < 21) {
      final tableInfo = await db.rawQuery("PRAGMA table_info(users)");
      final columns = tableInfo.map((c) => c['name'] as String).toList();
      if (!columns.contains('profile_image')) {
        await db.execute("ALTER TABLE users ADD COLUMN profile_image TEXT");
      }
    }

    if (oldVersion < 22) {
      // Data Migration: Sync existing profile images from students and teachers
      debugPrint("Migrating profile images to users table...");
      // Students
      await db.execute('''
        UPDATE users 
        SET profile_image = (SELECT profile_image FROM students WHERE students.user_id = users.id) 
        WHERE EXISTS (SELECT 1 FROM students WHERE students.user_id = users.id AND students.profile_image IS NOT NULL)
      ''');
      // Teachers
      await db.execute('''
        UPDATE users 
        SET profile_image = (SELECT profile_image FROM teachers WHERE teachers.user_id = users.id) 
        WHERE EXISTS (SELECT 1 FROM teachers WHERE teachers.user_id = users.id AND teachers.profile_image IS NOT NULL)
      ''');
    }

    if (oldVersion < 23) {
      // 14. Bundle Enrollments 
      await db.execute('''
        CREATE TABLE IF NOT EXISTS bundle_enrollments (
          id TEXT PRIMARY KEY,
          bundle_id TEXT NOT NULL,
          student_id TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'En curso',
          created_at TEXT NOT NULL,
          FOREIGN KEY (bundle_id) REFERENCES course_bundles (id) ON DELETE CASCADE,
          FOREIGN KEY (student_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');

      // Migrate existing bundle enrollments from individual groups
      await db.execute('''
        INSERT INTO bundle_enrollments (id, bundle_id, student_id, status, created_at)
        SELECT lower(hex(randomblob(16))), g.bundle_id, e.student_id, 'En curso', datetime('now')
        FROM enrollments e
        JOIN groups g ON e.group_id = g.id
        WHERE g.bundle_id IS NOT NULL
        GROUP BY g.bundle_id, e.student_id
      ''');
    }
  }
}
