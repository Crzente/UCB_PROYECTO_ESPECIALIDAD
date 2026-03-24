import 'dart:io';
import 'package:login_app/core/database/database_helper.dart';
import 'package:login_app/data/models/final_grade_history_model.dart';
import 'package:login_app/data/models/academic_year_report_model.dart';
import 'package:login_app/domain/entities/final_grade_history.dart';
import 'package:login_app/domain/entities/academic_year_report.dart';
import 'package:login_app/domain/repositories/academic_year_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as excel_lib;
import 'package:path_provider/path_provider.dart';

class AcademicYearRepositoryImpl implements AcademicYearRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  @override
  Future<void> closeGroup(String groupId) async {
    final db = await _dbHelper.database;

    // 1. Get group info
    final groupData = await db.rawQuery(
      '''
      SELECT g.*, c.name as course_name
      FROM groups g
      INNER JOIN courses c ON g.course_id = c.id
      WHERE g.id = ?
    ''',
      [groupId],
    );

    if (groupData.isEmpty) {
      throw Exception('Group not found');
    }

    final group = groupData.first;
    final groupStatus = group['status'] as String;

    if (groupStatus == 'archived') {
      throw Exception('Group is already closed');
    }

    final year = group['year'] as int;
    final courseName = group['course_name'] as String;
    final groupName = group['name'] as String;

    // 2. Get all enrollments for this group
    final enrollments = await db.rawQuery(
      '''
      SELECT e.*, u.name as student_name
      FROM enrollments e
      INNER JOIN users u ON e.student_id = u.id
      WHERE e.group_id = ?
    ''',
      [groupId],
    );

    // 3. For each enrollment, calculate final score and save to history
    for (var enrollment in enrollments) {
      final enrollmentId = enrollment['id'] as String;
      final studentId = enrollment['student_id'] as String;
      final studentName = enrollment['student_name'] as String;

      // Calculate final score
      final finalScore = await _calculateFinalScore(enrollmentId);

      // Determine status
      String status;
      if (finalScore == null) {
        status = 'incomplete';
      } else if (finalScore >= 51.0) {
        status = 'approved';
      } else {
        status = 'failed';
      }

      // Save to history
      final historyModel = FinalGradeHistoryModel(
        id: _uuid.v4(),
        studentId: studentId,
        studentName: studentName,
        courseId: group['course_id'] as String,
        courseName: courseName,
        groupId: groupId,
        groupName: groupName,
        year: year,
        finalScore: finalScore ?? 0.0,
        status: status,
        createdAt: DateTime.now(),
      );

      await db.insert('final_grades_history', historyModel.toMap());
    }

    // 4. Mark group as archived
    await db.update(
      'groups',
      {'status': 'archived'},
      where: 'id = ?',
      whereArgs: [groupId],
    );

    // 5. Update or create year summary
    await _updateYearSummary(year);
  }

  Future<void> _updateYearSummary(int year) async {
    final db = await _dbHelper.database;

    // Count statistics for this year
    final totalStudents = await _countUniqueStudents(year);
    final totalCourses = await _countUniqueCourses(year);
    final totalGroups = await _countTotalGroups(year);
    final closedGroups = await _countClosedGroups(year);

    // Check if report exists
    final existingReport = await db.query(
      'academic_year_reports',
      where: 'year = ?',
      whereArgs: [year],
    );

    final reportData = {
      'total_groups': totalGroups,
      'closed_groups': closedGroups,
      'active_groups': totalGroups - closedGroups,
    };

    if (existingReport.isEmpty) {
      // Create new report
      final reportModel = AcademicYearReportModel(
        id: _uuid.v4(),
        year: year,
        generatedAt: DateTime.now(),
        totalStudents: totalStudents,
        totalCourses: totalCourses,
        totalGroups: totalGroups,
        reportData: reportData,
      );
      await db.insert('academic_year_reports', reportModel.toMap());
    } else {
      // Update existing report
      await db.update(
        'academic_year_reports',
        {
          'total_students': totalStudents,
          'total_courses': totalCourses,
          'total_groups': totalGroups,
          'generated_at': DateTime.now().toIso8601String(),
          'report_data':
              '{"total_groups":$totalGroups,"closed_groups":$closedGroups,"active_groups":${totalGroups - closedGroups}}',
        },
        where: 'year = ?',
        whereArgs: [year],
      );
    }
  }

  Future<double?> _calculateFinalScore(String enrollmentId) async {
    final db = await _dbHelper.database;

    // Get all grades with their evaluation period weights
    final grades = await db.rawQuery(
      '''
      SELECT g.score, ep.weight
      FROM grades g
      INNER JOIN evaluation_periods ep ON g.evaluation_period_id = ep.id
      WHERE g.enrollment_id = ?
    ''',
      [enrollmentId],
    );

    if (grades.isEmpty) return null;

    double totalScore = 0.0;
    double totalWeight = 0.0;

    for (var grade in grades) {
      final score = grade['score'] as double?;
      final weight = grade['weight'] as double;

      if (score != null) {
        totalScore += score * (weight / 100);
        totalWeight += weight;
      }
    }

    // If not all grades are entered, return null
    if (totalWeight < 100.0) return null;

    return totalScore;
  }

  Future<int> _countUniqueStudents(int year) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(DISTINCT e.student_id) as count
      FROM enrollments e
      INNER JOIN groups g ON e.group_id = g.id
      WHERE g.year = ?
    ''',
      [year],
    );
    return result.first['count'] as int;
  }

  Future<int> _countUniqueCourses(int year) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(DISTINCT g.course_id) as count
      FROM groups g
      WHERE g.year = ?
    ''',
      [year],
    );
    return result.first['count'] as int;
  }

  Future<int> _countTotalGroups(int year) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count
      FROM groups
      WHERE year = ?
    ''',
      [year],
    );
    return result.first['count'] as int;
  }

  Future<int> _countClosedGroups(int year) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count
      FROM groups
      WHERE year = ? AND status = 'archived'
    ''',
      [year],
    );
    return result.first['count'] as int;
  }

  @override
  Future<List<int>> getAllYears() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT DISTINCT year FROM groups ORDER BY year DESC
    ''');
    return result.map((row) => row['year'] as int).toList();
  }

  @override
  Future<List<int>> getActiveYears() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT DISTINCT year FROM groups WHERE status = 'active' ORDER BY year DESC
    ''');
    return result.map((row) => row['year'] as int).toList();
  }

  @override
  Future<List<FinalGradeHistory>> getStudentGradesHistory(
    String studentId,
  ) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'final_grades_history',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'year DESC, course_name ASC',
    );
    return maps.map((map) => FinalGradeHistoryModel.fromMap(map)).toList();
  }

  @override
  Future<List<FinalGradeHistory>> getYearGradesHistory(int year) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'final_grades_history',
      where: 'year = ?',
      whereArgs: [year],
      orderBy: 'student_name ASC, course_name ASC',
    );
    return maps.map((map) => FinalGradeHistoryModel.fromMap(map)).toList();
  }

  @override
  Future<AcademicYearReport?> getYearSummary(int year) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'academic_year_reports',
      where: 'year = ?',
      whereArgs: [year],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return AcademicYearReportModel.fromMap(maps.first);
  }

  @override
  Future<String> generatePdfReport(int year) async {
    final report = await getYearSummary(year);
    final gradesHistory = await getYearGradesHistory(year);

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Reporte de Gestión Académica $year',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Año: $year'),
            if (report != null) ...[
              pw.SizedBox(height: 20),
              pw.Header(level: 1, child: pw.Text('Estadísticas Generales')),
              pw.Text('Total de Estudiantes: ${report.totalStudents}'),
              pw.Text('Total de Cursos: ${report.totalCourses}'),
              pw.Text('Total de Grupos: ${report.totalGroups}'),
            ],
            pw.SizedBox(height: 20),
            pw.Header(level: 1, child: pw.Text('Notas Finales')),
            if (gradesHistory.isNotEmpty)
              pw.TableHelper.fromTextArray(
                headers: [
                  'Estudiante',
                  'Curso',
                  'Grupo',
                  'Nota Final',
                  'Estado',
                ],
                data: gradesHistory
                    .map(
                      (grade) => [
                        grade.studentName,
                        grade.courseName,
                        grade.groupName,
                        grade.finalScore.toStringAsFixed(2),
                        _translateStatus(grade.status),
                      ],
                    )
                    .toList(),
              )
            else
              pw.Text('No hay notas registradas para este año'),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/reporte_gestion_$year.pdf');
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  @override
  Future<String> generateExcelReport(int year) async {
    final report = await getYearSummary(year);
    final gradesHistory = await getYearGradesHistory(year);

    var excel = excel_lib.Excel.createExcel();
    var sheet = excel['Reporte Gestión $year'];

    // Headers
    sheet.appendRow([
      excel_lib.TextCellValue('Estudiante'),
      excel_lib.TextCellValue('Curso'),
      excel_lib.TextCellValue('Grupo'),
      excel_lib.TextCellValue('Nota Final'),
      excel_lib.TextCellValue('Estado'),
    ]);

    // Data
    for (var grade in gradesHistory) {
      sheet.appendRow([
        excel_lib.TextCellValue(grade.studentName),
        excel_lib.TextCellValue(grade.courseName),
        excel_lib.TextCellValue(grade.groupName),
        excel_lib.DoubleCellValue(grade.finalScore),
        excel_lib.TextCellValue(_translateStatus(grade.status)),
      ]);
    }

    // Add summary sheet
    var summarySheet = excel['Resumen'];
    summarySheet.appendRow([
      excel_lib.TextCellValue('Gestión Académica $year'),
    ]);
    summarySheet.appendRow([excel_lib.TextCellValue('')]);
    if (report != null) {
      summarySheet.appendRow([
        excel_lib.TextCellValue('Total Estudiantes:'),
        excel_lib.IntCellValue(report.totalStudents),
      ]);
      summarySheet.appendRow([
        excel_lib.TextCellValue('Total Cursos:'),
        excel_lib.IntCellValue(report.totalCourses),
      ]);
      summarySheet.appendRow([
        excel_lib.TextCellValue('Total Grupos:'),
        excel_lib.IntCellValue(report.totalGroups),
      ]);
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/reporte_gestion_$year.xlsx');
    await file.writeAsBytes(excel.encode()!);

    return file.path;
  }

  @override
  Future<String> generateStudentCertificate(String studentId, int year) async {
    final db = await _dbHelper.database;
    final studentData = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [studentId],
      limit: 1,
    );
    if (studentData.isEmpty) throw Exception('Student not found');

    final studentName = studentData.first['name'] as String;
    final grades = await db.query(
      'final_grades_history',
      where: 'student_id = ? AND year = ?',
      whereArgs: [studentId, year],
      orderBy: 'course_name ASC',
    );

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'CERTIFICADO DE NOTAS',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Text(
                  'Se certifica que:',
                  style: const pw.TextStyle(fontSize: 16),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  studentName,
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Ha cursado las siguientes materias durante la gestión $year:',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 30),
                if (grades.isNotEmpty)
                  pw.TableHelper.fromTextArray(
                    headers: ['Materia', 'Nota Final', 'Estado'],
                    data: grades
                        .map(
                          (grade) => [
                            grade['course_name'],
                            (grade['final_score'] as double).toStringAsFixed(2),
                            _translateStatus(grade['status'] as String),
                          ],
                        )
                        .toList(),
                  )
                else
                  pw.Text('No hay materias registradas'),
                pw.SizedBox(height: 40),
                pw.Text(
                  'Fecha de emisión: ${_formatDate(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/certificado_${studentName.replaceAll(' ', '_')}_$year.pdf',
    );
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'approved':
        return 'Aprobado';
      case 'failed':
        return 'Reprobado';
      case 'incomplete':
        return 'Incompleto';
      default:
        return status;
    }
  }
}
