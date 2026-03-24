import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Core & Data
import 'core/database/database_helper.dart';
import 'data/repositories/user_repository_impl.dart';
import 'data/repositories/course_repository_impl.dart';
import 'data/repositories/group_repository_impl.dart';
import 'data/repositories/enrollment_repository_impl.dart';
import 'data/repositories/evaluation_repository_impl.dart';
import 'data/repositories/grade_repository_impl.dart';
import 'data/repositories/academic_config_repository_impl.dart';
import 'data/repositories/student_repository_impl.dart'; // Added
import 'data/repositories/teacher_repository_impl.dart'; // Added
import 'data/repositories/course_bundle_repository_impl.dart'; // Added

import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/course_provider.dart';
import 'presentation/providers/group_provider.dart';
import 'presentation/providers/enrollment_provider.dart';
import 'presentation/providers/user_management_provider.dart';
import 'presentation/providers/grade_provider.dart';
import 'presentation/providers/evaluation_provider.dart';
import 'presentation/providers/academic_config_provider.dart';
import 'presentation/providers/academic_year_provider.dart';
import 'presentation/providers/student_provider.dart'; // Added
import 'presentation/providers/teacher_provider.dart'; // Added
import 'presentation/providers/course_bundle_provider.dart'; // Added
import 'presentation/screens/auth/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final dbHelper = DatabaseHelper.instance;
  // Safety: Force admin user to have admin role in case it was modified during testing
  await dbHelper.repairAdminUser();

  final userRepository = UserRepositoryImpl(dbHelper: dbHelper);
  final courseRepository = CourseRepositoryImpl(dbHelper: dbHelper);
  final groupRepository = GroupRepositoryImpl(dbHelper: dbHelper);
  final enrollmentRepository = EnrollmentRepositoryImpl(dbHelper: dbHelper);
  final evaluationRepository = EvaluationRepositoryImpl(dbHelper: dbHelper);
  final academicConfigRepository = AcademicConfigRepositoryImpl(
    dbHelper: dbHelper,
  );
  final gradeRepository = GradeRepositoryImpl(dbHelper: dbHelper);
  final studentRepository = StudentRepositoryImpl(); // dbHelper internal
  final teacherRepository = TeacherRepositoryImpl(); // dbHelper internal
  final courseBundleRepository = CourseBundleRepositoryImpl(dbHelper: dbHelper);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(userRepository: userRepository),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              CourseBundleProvider(repository: courseBundleRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => CourseProvider(courseRepository: courseRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => EnrollmentProvider(
            enrollmentRepository: enrollmentRepository,
            userRepository: userRepository,
            groupRepository: groupRepository,
            evaluationRepository: evaluationRepository,
            gradeRepository: gradeRepository,
          ),
        ),
        ChangeNotifierProxyProvider<EnrollmentProvider, GroupProvider>(
          create: (context) => GroupProvider(
            groupRepository: groupRepository,
            userRepository: userRepository,
            enrollmentProvider: Provider.of<EnrollmentProvider>(
              context,
              listen: false,
            ),
          ),
          update: (context, enrollmentProvider, previous) {
            if (previous != null) {
              previous.enrollmentProvider = enrollmentProvider;
              return previous;
            }
            return GroupProvider(
              groupRepository: groupRepository,
              userRepository: userRepository,
              enrollmentProvider: enrollmentProvider,
            );
          },
        ),
        ChangeNotifierProvider(
          create: (_) => UserManagementProvider(userRepository: userRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => EvaluationProvider(
            repository: evaluationRepository,
            courseRepository: courseRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              AcademicConfigProvider(repository: academicConfigRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => GradeProvider(repository: gradeRepository),
        ),
        ChangeNotifierProvider(create: (_) => AcademicYearProvider()),
        ChangeNotifierProvider(
          create: (_) => StudentProvider(studentRepository: studentRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => TeacherProvider(teacherRepository: teacherRepository),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'School Management',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6366f1)),
        useMaterial3: true,
        fontFamily: GoogleFonts.poppins().fontFamily,
      ),
      home: const LoginPage(),
    );
  }
}
