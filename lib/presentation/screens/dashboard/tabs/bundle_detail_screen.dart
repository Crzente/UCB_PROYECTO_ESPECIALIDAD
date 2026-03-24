import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../domain/entities/course_bundle.dart';
import '../../../../domain/entities/enrollment.dart';
import '../../../providers/group_provider.dart';
import '../../../providers/enrollment_provider.dart';
import '../../../providers/grade_provider.dart';
import '../../../providers/evaluation_provider.dart';
import '../../../providers/student_provider.dart';
import '../../../../core/utils/military_rank_utils.dart';

class BundleDetailScreen extends StatefulWidget {
  final CourseBundle bundle;

  const BundleDetailScreen({super.key, required this.bundle});

  @override
  State<BundleDetailScreen> createState() => _BundleDetailScreenState();
}

class _BundleDetailScreenState extends State<BundleDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bundleId = widget.bundle.id;
      context.read<EnrollmentProvider>().loadBundleEnrollments(bundleId);
      context.read<EvaluationProvider>().loadBundlePeriods(bundleId);
      context.read<GradeProvider>().loadGradesByBundle(bundleId);
      context.read<StudentProvider>().loadStudents();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStudentsSubjectsTab(),
                _buildGradesConsolidatedTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.bundle.name,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Reporte Consolidado • Gestión ${widget.bundle.academicYear}",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF3B82F6),
              indicatorWeight: 4,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: "Alumnos del Curso"),
                Tab(text: "Consolidado de Notas"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _showAllStudentsList = true;

  Widget _buildStudentsSubjectsTab() {
    final enrollmentProvider = context.watch<EnrollmentProvider>();
    final studentProvider = context.watch<StudentProvider>();

    if (enrollmentProvider.isLoading || studentProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final allEnrollments = enrollmentProvider.enrollments;

    // Filter enrollments to get unique students (per bundle)
    // Actually enrollmentProvider.enrollments for a bundle should already have one entry per student-subject.
    // We need to group by student to show them in the list.
    final Map<String, Enrollment> patientToEnrollment = {};
    for (var e in allEnrollments) {
      if (!patientToEnrollment.containsKey(e.studentId)) {
        patientToEnrollment[e.studentId] = e;
      }
    }

    final List<Enrollment> bundleStudents = patientToEnrollment.values.toList();
    final filteredStudents = _showAllStudentsList
        ? bundleStudents
        : bundleStudents.where((e) => e.status == 'En curso').toList();

    if (bundleStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "Sin alumnos inscritos",
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "Mostrar todos:",
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  Switch(
                    value: _showAllStudentsList,
                    onChanged: (val) =>
                        setState(() => _showAllStudentsList = val),
                    activeColor: const Color(0xFF3B82F6),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFFF1F5F9),
                  ),
                  columns: [
                    DataColumn(
                      label: Text(
                        'Grado',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Compl.',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Nombres y Apellidos',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Estado',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Acción',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                  rows: filteredStudents.map((en) {
                    final bool isActive = en.status == 'En curso';

                    String grade = '-';
                    String specialty = '-';
                    try {
                      final student = studentProvider.students.firstWhere(
                        (s) => s.userId == en.studentId,
                      );
                      grade = student.grade.isEmpty
                          ? '-'
                          : MilitaryRankUtils.abreviarGrado(student.grade);
                      specialty =
                          (student.specialty == null ||
                              student.specialty!.isEmpty)
                          ? '-'
                          : student.specialty!;
                    } catch (_) {}

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            grade,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: isActive
                                  ? const Color(0xFF1E293B)
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            specialty,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: isActive
                                  ? const Color(0xFF1E293B)
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            en.studentName ?? 'Desconocido',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: isActive
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                              color: isActive
                                  ? const Color(0xFF1E293B)
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.green.shade50
                                  : (en.status == 'Suspendido'
                                        ? Colors.orange.shade50
                                        : Colors.red.shade50),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              en.status,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isActive
                                    ? Colors.green.shade700
                                    : (en.status == 'Suspendido'
                                          ? Colors.orange.shade700
                                          : Colors.red.shade700),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_horiz, size: 18),
                            tooltip: "Cambiar estado",
                            onSelected: (newStatus) =>
                                _changeStudentStatus(en.studentId, newStatus),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'En curso',
                                child: Text("Reactivar (En curso)"),
                              ),
                              const PopupMenuItem(
                                value: 'Suspendido',
                                child: Text("Suspender"),
                              ),
                              const PopupMenuItem(
                                value: 'Retirado',
                                child: Text("Retirar"),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradesConsolidatedTab() {
    final enrollmentProvider = context.watch<EnrollmentProvider>();
    final gradeProvider = context.watch<GradeProvider>();
    final groupProvider = context.watch<GroupProvider>();
    final evaluationProvider = context.watch<EvaluationProvider>();
    final studentProvider = context.watch<StudentProvider>();

    if (enrollmentProvider.isLoading || gradeProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final bundleGroups = groupProvider.groups
        .where((g) => g.bundleId == widget.bundle.id)
        .toList();
    final enrollments = enrollmentProvider.enrollments;
    final periods = evaluationProvider.periods;

    final Set<String> studentIds = enrollments.map((e) => e.studentId).toSet();
    final Map<String, String> studentIdToName = {};
    final Map<String, String> studentIdToGrade = {};
    final Map<String, String> studentIdToSpecialty = {};

    for (var e in enrollments) {
      if (!studentIdToName.containsKey(e.studentId)) {
        studentIdToName[e.studentId] = e.studentName ?? "Desconocido";

        // Get grade and specialty from student profile
        try {
          final student = studentProvider.students.firstWhere(
            (s) => s.id == e.studentId,
          );
          studentIdToGrade[e.studentId] = student.grade.isEmpty
              ? '-'
              : MilitaryRankUtils.abreviarGrado(student.grade);
          studentIdToSpecialty[e.studentId] =
              (student.specialty == null || student.specialty!.isEmpty)
              ? '-'
              : student.specialty!;
        } catch (ex) {
          studentIdToGrade[e.studentId] = '-';
          studentIdToSpecialty[e.studentId] = '-';
        }
      }
    }

    if (studentIds.isEmpty) {
      return Center(
        child: Text(
          "No hay registros de notas aún.",
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Consolidado de Calificaciones",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFFF1F5F9),
                  ),
                  horizontalMargin: 20,
                  columnSpacing: 30,
                  columns: [
                    DataColumn(
                      label: Text(
                        "Grado",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Compl.",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Alumno",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...bundleGroups.map(
                      (g) => DataColumn(
                        label: Text(
                          g.courseName ?? "Materia",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Promedio",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                  rows: studentIds.map((sid) {
                    double studentTotal = 0;
                    int subjectCount = 0;

                    final cells = bundleGroups.map((g) {
                      final enrollmentMatches = enrollments.where(
                        (e) => e.studentId == sid && e.groupId == g.id,
                      );

                      if (enrollmentMatches.isEmpty) {
                        return const DataCell(Center(child: Text("-")));
                      }
                      final enrollment = enrollmentMatches.first;

                      double subjectScore = 0;
                      final groupPeriods = periods.where(
                        (p) => p.groupId == g.id,
                      );

                      for (var p in groupPeriods) {
                        final s = gradeProvider.getScore(enrollment.id, p.id);
                        if (s != null) {
                          subjectScore += s * (p.weight / 100);
                        }
                      }

                      studentTotal += subjectScore;
                      subjectCount++;

                      return DataCell(
                        Center(
                          child: Text(
                            subjectScore.toStringAsFixed(1),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: subjectScore < 60
                                  ? Colors.red
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    }).toList();

                    double avg = subjectCount > 0
                        ? studentTotal / subjectCount
                        : 0;

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            studentIdToGrade[sid] ?? '-',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          Text(
                            studentIdToSpecialty[sid] ?? '-',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          Text(
                            studentIdToName[sid] ?? "",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        ...cells,
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: avg >= 60
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              avg.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: avg >= 60
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeStudentStatus(String studentId, String newStatus) async {
    final provider = context.read<EnrollmentProvider>();
    try {
      await provider.updateStudentStatusInBundle(
        studentId,
        widget.bundle.id,
        newStatus,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Estado actualizado a $newStatus")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al cambiar estado: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
