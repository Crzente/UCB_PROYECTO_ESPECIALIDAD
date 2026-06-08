import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:excel/excel.dart';
import '../../domain/entities/student.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/course_bundle.dart';
import '../../domain/entities/group.dart';
import '../../domain/entities/enrollment.dart';
import '../../domain/entities/evaluation_period.dart';
import '../../presentation/providers/grade_provider.dart';
import '../../core/utils/military_rank_utils.dart';

class PdfService {
  static Future<pw.Font> _loadFont() async {
    // Fallback to standard font since custom font asset is missing
    return pw.Font.helvetica();
  }

  static Future<File> _getOutputDirectory(
    String fileName,
    String extension,
  ) async {
    // Try to get downloads directory first, fallback to documents
    Directory? outputDir;

    if (Platform.isWindows) {
      // On Windows, try to find the "Downloads" folder, or fallback to User Home
      // getDownloadsDirectory() is available in path_provider 2.0.4+
      outputDir = await getDownloadsDirectory();
    }

    outputDir ??= await getApplicationDocumentsDirectory();

    return File(
      "${outputDir.path}${Platform.pathSeparator}$fileName.$extension",
    );
  }

  static Future<void> _saveAndOpenPdf(pw.Document pdf, String fileName) async {
    final file = await _getOutputDirectory(fileName, 'pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  static Future<void> _saveAndOpenExcel(Excel excel, String fileName) async {
    final file = await _getOutputDirectory(fileName, 'xlsx');
    final List<int>? fileBytes = excel.save();
    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes);
      await OpenFile.open(file.path);
    } else {
      throw Exception('No se pudieron generar los bytes del archivo Excel');
    }
  }

  // --- PDF GENERATORS ---

  static Future<void> generateCourseReport(
    CourseBundle bundle,
    List<Student> students,
    List<Group> groups,
    List<Enrollment> enrollments,
    List<EvaluationPeriod> periods,
    GradeProvider gradeProvider,
  ) async {
    final pdf = pw.Document();
    final ttf = await _loadFont();

    // Create student ID to data maps (like in bundle_detail_screen)
    final Map<String, String> studentIdToName = {};
    final Map<String, String> studentIdToGrade = {};
    final Map<String, String> studentIdToSpecialty = {};

    for (var s in students) {
      studentIdToName[s.id] = s.user?.name ?? '';
      studentIdToGrade[s.id] = s.grade;
      studentIdToSpecialty[s.id] = s.specialty ?? '';
    }

    final studentIds = students.map((s) => s.id).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "EPTA",
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    "Gestión ${bundle.academicYear}",
                    style: pw.TextStyle(font: ttf, fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text(
                "CONSOLIDADO DE CALIFICACIONES - ${bundle.name.toUpperCase()}",
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: [
                'Grado',
                'Compl.',
                'Alumno',
                ...groups.map((g) => g.courseName ?? 'Materia'),
                'Promedio',
              ],
              data: studentIds.map((sid) {
                // This is the EXACT logic from bundle_detail_screen lines 526-571
                double studentTotal = 0;
                int subjectCount = 0;

                final cells = groups.map((g) {
                  final enrollmentMatches = enrollments.where(
                    (e) => e.studentId == sid && e.groupId == g.id,
                  );

                  if (enrollmentMatches.isEmpty) {
                    return '-';
                  }
                  final enrollment = enrollmentMatches.first;

                  double subjectScore = 0;
                  final groupPeriods = periods.where((p) => p.groupId == g.id);

                  for (var p in groupPeriods) {
                    final s = gradeProvider.getScore(enrollment.id, p.id);
                    if (s != null) {
                      subjectScore += s * (p.weight / 100);
                    }
                  }

                  studentTotal += subjectScore;
                  subjectCount++;

                  return subjectScore.toStringAsFixed(1);
                }).toList();

                double avg = subjectCount > 0 ? studentTotal / subjectCount : 0;

                return [
                  MilitaryRankUtils.abreviarGrado(studentIdToGrade[sid] ?? '-'),
                  studentIdToSpecialty[sid] ?? '-',
                  studentIdToName[sid] ?? '',
                  ...cells,
                  avg.toStringAsFixed(1),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                font: ttf,
                fontWeight: pw.FontWeight.bold,
                fontSize: 8,
              ),
              cellStyle: pw.TextStyle(font: ttf, fontSize: 8),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
            ),
          ];
        },
      ),
    );

    await _saveAndOpenPdf(
      pdf,
      "reporte_curso_${bundle.name.replaceAll(' ', '_')}",
    );
  }

  static Future<void> generateStudentBulletin(
    Student student,
    List<Group> enrolledGroups,
    List<EvaluationPeriod> allPeriods,
    GradeProvider gradeProvider,
    List<Enrollment> enrollments,
  ) async {
    final pdf = pw.Document();
    final ttf = await _loadFont();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Center(
                  child: pw.Text(
                    "BOLETÍN DE CALIFICACIONES",
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                child: pw.Row(
                  children: [
                    pw.Text(
                      "Grado: ${MilitaryRankUtils.abreviarGrado(student.grade.isNotEmpty ? student.grade : '-')}",
                      style: pw.TextStyle(font: ttf, fontSize: 12),
                    ),
                    pw.SizedBox(width: 20),
                    pw.Text(
                      "Compl.: ${student.specialty ?? ''}",
                      style: pw.TextStyle(font: ttf, fontSize: 12),
                    ),
                    pw.SizedBox(width: 20),
                    pw.Expanded(
                      child: pw.Text(
                        "Nombres: ${student.user?.name ?? ''}",
                        style: pw.TextStyle(font: ttf, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              pw.TableHelper.fromTextArray(
                context: context,
                headers: ['Materia', 'Promedio Final'],
                columnWidths: {
                  0: const pw.FlexColumnWidth(),
                  1: const pw.FixedColumnWidth(100),
                },
                data: enrolledGroups.map((g) {
                  final enrollmentMatches = enrollments.where(
                    (e) => e.studentId == student.id && e.groupId == g.id,
                  );
                  if (enrollmentMatches.isEmpty) {
                    return [g.courseName ?? 'Materia', '-'];
                  }

                  final enrollment = enrollmentMatches.first;
                  final groupPeriods = allPeriods.where(
                    (p) => p.groupId == g.id,
                  );

                  double subjectScore = 0;

                  for (var p in groupPeriods) {
                    final score = gradeProvider.getScore(enrollment.id, p.id);
                    if (score != null) {
                      subjectScore += score * (p.weight / 100);
                    }
                  }

                  return [
                    g.courseName ?? 'Materia',
                    subjectScore.toStringAsFixed(1),
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  font: ttf,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
                cellStyle: pw.TextStyle(font: ttf, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
              ),
            ],
          );
        },
      ),
    );
    await _saveAndOpenPdf(pdf, "boletin_${student.studentCode}");
  }

  static Future<void> generateSubjectReport(
    Course course,
    List<Student> students,
    List<EvaluationPeriod> periods,
    GradeProvider gradeProvider,
    List<Enrollment>
    enrollments, // We need enrollments to find the enrollment ID for the student in this course
    String
    groupId, // We need the group ID to filter periods and grades for this specific subject/group
  ) async {
    final pdf = pw.Document();
    final ttf = await _loadFont();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                "LISTA DE CALIFICACIONES - ${course.name.toUpperCase()}",
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              "Código Materia: ${course.code ?? ''}",
              style: pw.TextStyle(font: ttf),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: [
                'N°',
                'Grado',
                'Compl.',
                'Nombres y Apellidos',
                ...periods.map((p) => p.name),
                'Promedio',
              ],
              columnWidths: {
                0: const pw.FixedColumnWidth(20),
                1: const pw.FixedColumnWidth(40),
                2: const pw.FixedColumnWidth(40),
                3: const pw.FlexColumnWidth(),
                for (var i = 0; i < periods.length; i++)
                  (i + 4): const pw.FixedColumnWidth(40),
                (periods.length + 4): const pw.FixedColumnWidth(40),
              },
              data: List.generate(students.length, (index) {
                final s = students[index];

                // Find enrollment for this student in this group/course
                final enrollmentMatches = enrollments.where(
                  (e) => e.studentId == s.id && e.groupId == groupId,
                );

                if (enrollmentMatches.isEmpty) {
                  return [
                    (index + 1).toString(),
                    MilitaryRankUtils.abreviarGrado(
                      s.grade.isNotEmpty ? s.grade : '-',
                    ),
                    s.specialty ?? '',
                    s.user?.name ?? '',
                    ...List.filled(periods.length, '-'),
                    '-',
                  ];
                }

                final enrollment = enrollmentMatches.first;
                double subjectScore = 0;

                final gradeCells = periods.map((p) {
                  final score = gradeProvider.getScore(enrollment.id, p.id);

                  if (score != null) {
                    subjectScore += score * (p.weight / 100);
                    return score.toStringAsFixed(1);
                  }
                  return '-';
                }).toList();

                return [
                  (index + 1).toString(),
                  MilitaryRankUtils.abreviarGrado(
                    s.grade.isNotEmpty ? s.grade : '-',
                  ),
                  s.specialty ?? '',
                  s.user?.name ?? '',
                  ...gradeCells,
                  subjectScore.toStringAsFixed(1),
                ];
              }),
              headerStyle: pw.TextStyle(
                font: ttf,
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              cellStyle: pw.TextStyle(font: ttf, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
            ),
          ];
        },
      ),
    );
    await _saveAndOpenPdf(pdf, "lista_${course.code ?? 'materia'}");
  }

  // --- EXCEL GENERATORS ---

  static Future<void> generateCourseExcel(
    CourseBundle bundle,
    List<Student> students,
    List<Group> groups,
    List<Enrollment> enrollments,
    List<EvaluationPeriod> periods,
    GradeProvider gradeProvider,
  ) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Sheet1'];

    // Create student ID to data maps (same as PDF)
    final Map<String, String> studentIdToName = {};
    final Map<String, String> studentIdToGrade = {};
    final Map<String, String> studentIdToSpecialty = {};

    for (var s in students) {
      studentIdToName[s.id] = s.user?.name ?? '';
      studentIdToGrade[s.id] = s.grade;
      studentIdToSpecialty[s.id] = s.specialty ?? '';
    }

    final studentIds = students.map((s) => s.id).toList();

    // Title
    sheet.appendRow([
      TextCellValue('CONSOLIDADO DE CALIFICACIONES - ${bundle.name}'),
    ]);
    sheet.appendRow([TextCellValue('Gestión ${bundle.academicYear}')]);
    sheet.appendRow([TextCellValue('')]);

    // Headers
    List<String> headers = [
      'Grado',
      'Compl.',
      'Alumno',
      ...groups.map((g) => g.courseName ?? 'Materia'),
      'Promedio',
    ];

    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    // Data - EXACT logic from bundle_detail_screen
    for (var sid in studentIds) {
      double studentTotal = 0;
      int subjectCount = 0;

      final cells = groups.map((g) {
        final enrollmentMatches = enrollments.where(
          (e) => e.studentId == sid && e.groupId == g.id,
        );

        if (enrollmentMatches.isEmpty) {
          return TextCellValue('-');
        }
        final enrollment = enrollmentMatches.first;

        double subjectScore = 0;
        final groupPeriods = periods.where((p) => p.groupId == g.id);

        for (var p in groupPeriods) {
          final s = gradeProvider.getScore(enrollment.id, p.id);
          if (s != null) {
            subjectScore += s * (p.weight / 100);
          }
        }

        studentTotal += subjectScore;
        subjectCount++;

        return TextCellValue(subjectScore.toStringAsFixed(1));
      }).toList();

      double avg = subjectCount > 0 ? studentTotal / subjectCount : 0;

      sheet.appendRow([
        TextCellValue(
          MilitaryRankUtils.abreviarGrado(studentIdToGrade[sid] ?? '-'),
        ),
        TextCellValue(studentIdToSpecialty[sid] ?? '-'),
        TextCellValue(studentIdToName[sid] ?? ''),
        ...cells,
        TextCellValue(avg.toStringAsFixed(1)),
      ]);
    }

    await _saveAndOpenExcel(
      excel,
      "reporte_curso_${bundle.name.replaceAll(' ', '_')}",
    );
  }

  static Future<void> generateStudentBulletinExcel(
    Student student,
    List<Group> enrolledGroups,
    List<EvaluationPeriod> allPeriods,
    GradeProvider gradeProvider,
    List<Enrollment> enrollments,
  ) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Sheet1'];

    sheet.appendRow([TextCellValue('BOLETÍN DE CALIFICACIONES')]);

    // Header Info
    sheet.appendRow([
      TextCellValue(
        'Grado: ${MilitaryRankUtils.abreviarGrado(student.grade.isNotEmpty ? student.grade : '-')}}',
      ),
      TextCellValue('Compl.: ${student.specialty ?? ''}'),
      TextCellValue('Nombre: ${student.user?.name ?? ''}'),
    ]);

    sheet.appendRow([TextCellValue('')]); // Spacer

    // Table Header
    sheet.appendRow([
      TextCellValue('Materia'),
      TextCellValue('Promedio Final'),
    ]);

    // Data
    for (var g in enrolledGroups) {
      final enrollmentMatches = enrollments.where(
        (e) => e.studentId == student.id && e.groupId == g.id,
      );
      if (enrollmentMatches.isEmpty) {
        sheet.appendRow([
          TextCellValue(g.courseName ?? 'Materia'),
          TextCellValue('-'),
        ]);
        continue;
      }

      final enrollment = enrollmentMatches.first;
      final groupPeriods = allPeriods.where((p) => p.groupId == g.id);

      double subjectScore = 0;
      for (var p in groupPeriods) {
        final score = gradeProvider.getScore(enrollment.id, p.id);
        if (score != null) {
          subjectScore += score * (p.weight / 100);
        }
      }

      sheet.appendRow([
        TextCellValue(g.courseName ?? 'Materia'),
        TextCellValue(subjectScore.toStringAsFixed(1)),
      ]);
    }

    await _saveAndOpenExcel(excel, "boletin_${student.studentCode}");
  }

  static Future<void> generateSubjectExcel(
    Course course,
    List<Student> students,
    List<EvaluationPeriod> periods,
    GradeProvider gradeProvider,
    List<Enrollment> enrollments,
    String groupId,
  ) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Sheet1'];

    sheet.appendRow([TextCellValue('LISTA DE CALIFICACIONES: ${course.name}')]);
    sheet.appendRow([TextCellValue('Código: ${course.code ?? ''}')]);
    sheet.appendRow([TextCellValue('')]);

    // Headers
    List<String> headers = [
      'N°',
      'Grado',
      'Compl.',
      'Nombres y Apellidos',
      ...periods.map((p) => p.name),
      'Promedio',
    ];

    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    for (var i = 0; i < students.length; i++) {
      final s = students[i];

      // Find enrollment for this student in this group
      final enrollmentMatches = enrollments.where(
        (e) => e.studentId == s.id && e.groupId == groupId,
      );

      if (enrollmentMatches.isEmpty) {
        sheet.appendRow([
          IntCellValue(i + 1),
          TextCellValue(
            MilitaryRankUtils.abreviarGrado(s.grade.isNotEmpty ? s.grade : '-'),
          ),
          TextCellValue(s.specialty ?? ''),
          TextCellValue(s.user?.name ?? ''),
          ...List.filled(periods.length, TextCellValue('-')),
          TextCellValue('-'),
        ]);
        continue;
      }

      final enrollment = enrollmentMatches.first;
      double subjectScore = 0;

      final gradeCells = periods.map((p) {
        final score = gradeProvider.getScore(enrollment.id, p.id);
        if (score != null) {
          subjectScore += score * (p.weight / 100);
          return TextCellValue(score.toStringAsFixed(1));
        }
        return TextCellValue('-');
      }).toList();

      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(
          MilitaryRankUtils.abreviarGrado(s.grade.isNotEmpty ? s.grade : '-'),
        ),
        TextCellValue(s.specialty ?? ''),
        TextCellValue(s.user?.name ?? ''),
        ...gradeCells,
        TextCellValue(subjectScore.toStringAsFixed(1)),
      ]);
    }

    await _saveAndOpenExcel(excel, "lista_${course.code ?? 'materia'}");
  }
}
