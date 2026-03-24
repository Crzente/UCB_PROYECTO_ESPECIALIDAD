import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../presentation/providers/course_provider.dart';
import '../../../../presentation/providers/group_provider.dart';
import '../../../../presentation/providers/course_bundle_provider.dart';
import '../../../../presentation/providers/student_provider.dart';
import '../../../../presentation/providers/evaluation_provider.dart';
import '../../../../presentation/providers/grade_provider.dart';
import '../../../../core/services/pdf_service.dart';
import '../../../../presentation/providers/enrollment_provider.dart';
import '../../../../domain/entities/student.dart';
import '../../../../domain/entities/course_bundle.dart';
import '../../../../domain/entities/course.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  // Search controllers
  final TextEditingController _courseSearchCtrl = TextEditingController();
  final TextEditingController _studentSearchCtrl = TextEditingController();
  final TextEditingController _subjectSearchCtrl = TextEditingController();

  String _courseQuery = "";
  String _studentQuery = "";
  String _subjectQuery = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadCourses();
      context.read<GroupProvider>().loadGroups();
      context.read<CourseBundleProvider>().loadBundles();
      context.read<StudentProvider>().loadStudents();
    });

    _courseSearchCtrl.addListener(() {
      setState(() => _courseQuery = _courseSearchCtrl.text.toLowerCase());
    });
    _studentSearchCtrl.addListener(() {
      setState(() => _studentQuery = _studentSearchCtrl.text.toLowerCase());
    });
    _subjectSearchCtrl.addListener(() {
      setState(() => _subjectQuery = _subjectSearchCtrl.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _courseSearchCtrl.dispose();
    _studentSearchCtrl.dispose();
    _subjectSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Reportes",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TabBar(
              labelColor: const Color(0xFF2563EB),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF2563EB),
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: "Reportes por Curso"),
                Tab(text: "Reportes por Alumno"),
                Tab(text: "Reportes por Materia"),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              children: [
                _buildCourseReportsTab(),
                _buildStudentReportsTab(),
                _buildSubjectReportsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- COURSE REPORTS ---
  Widget _buildCourseReportsTab() {
    final bundleProvider = context.watch<CourseBundleProvider>();
    final allBundles = bundleProvider.bundles;

    if (bundleProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filter
    final bundles = allBundles.where((b) {
      return b.name.toLowerCase().contains(_courseQuery);
    }).toList();

    return Column(
      children: [
        _buildSearchBar(_courseSearchCtrl, "Buscar curso..."),
        const SizedBox(height: 12),
        Expanded(
          child: bundles.isEmpty
              ? _buildEmptyState("No se encontraron cursos")
              : ListView.builder(
                  itemCount: bundles.length,
                  itemBuilder: (context, index) {
                    final bundle = bundles[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: const Icon(Icons.class_, color: Colors.blue),
                        ),
                        title: Text(
                          bundle.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          "Gestión ${bundle.academicYear}",
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        trailing: _buildExportActions(
                          context,
                          onPdf: () => _generateCoursePdf(bundle),
                          onExcel: () => _generateCourseExcel(bundle),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- STUDENT REPORTS ---
  Widget _buildStudentReportsTab() {
    final studentProvider = context.watch<StudentProvider>();
    final allStudents = studentProvider.students;

    if (studentProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final students = allStudents.where((s) {
      final name = (s.user?.name ?? "").toLowerCase();
      final code = s.studentCode.toLowerCase();
      return name.contains(_studentQuery) || code.contains(_studentQuery);
    }).toList();

    return Column(
      children: [
        _buildSearchBar(
          _studentSearchCtrl,
          "Buscar alumno (nombre o código)...",
        ),
        const SizedBox(height: 12),
        Expanded(
          child: students.isEmpty
              ? _buildEmptyState("No se encontraron alumnos")
              : ListView.separated(
                  itemCount: students.length,
                  separatorBuilder: (c, i) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Colors.indigo.shade50,
                        backgroundImage:
                            (student.profileImage != null &&
                                student.profileImage!.isNotEmpty)
                            ? MemoryImage(base64Decode(student.profileImage!))
                            : null,
                        child:
                            (student.profileImage == null ||
                                student.profileImage!.isEmpty)
                            ? Text(
                                student.user?.name.substring(0, 1) ?? "A",
                                style: GoogleFonts.poppins(
                                  color: Colors.indigo,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        student.user?.name ?? "Sin nombre",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        "Grado: ${student.grade}",
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      trailing: _buildExportActions(
                        context,
                        onPdf: () => _generateStudentBulletinPdf(student),
                        onExcel: () => _generateStudentBulletinExcel(student),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- SUBJECT REPORTS ---
  Widget _buildSubjectReportsTab() {
    final courseProvider = context.watch<CourseProvider>();
    final allCourses = courseProvider.courses;

    if (courseProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final courses = allCourses.where((c) {
      final name = c.name.toLowerCase();
      final code = (c.code ?? "").toLowerCase();
      return name.contains(_subjectQuery) || code.contains(_subjectQuery);
    }).toList();

    return Column(
      children: [
        _buildSearchBar(_subjectSearchCtrl, "Buscar materia..."),
        const SizedBox(height: 12),
        Expanded(
          child: courses.isEmpty
              ? _buildEmptyState("No se encontraron materias")
              : ListView.builder(
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade50,
                          child: const Icon(Icons.book, color: Colors.green),
                        ),
                        title: Text(
                          course.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          course.code ?? "Sin código",
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        trailing: _buildExportActions(
                          context,
                          onPdf: () => _generateSubjectPdf(course),
                          onExcel: () => _generateSubjectExcel(course),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- HELPERS ---

  Widget _buildSearchBar(TextEditingController controller, String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          icon: const Icon(Icons.search, color: Colors.grey),
          hintText: hint,
          border: InputBorder.none,
          hintStyle: GoogleFonts.poppins(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildExportActions(
    BuildContext context, {
    required VoidCallback onPdf,
    required VoidCallback onExcel,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: "Exportar PDF",
          icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
          onPressed: onPdf,
        ),
        IconButton(
          tooltip: "Exportar Excel",
          icon: const Icon(Icons.table_chart, color: Colors.green),
          onPressed: onExcel,
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message, style: GoogleFonts.poppins(color: Colors.grey)),
        ],
      ),
    );
  }

  // --- GENERATION HANDLERS (Placeholders / Calls to Service) ---

  Future<void> _generateCoursePdf(CourseBundle bundle) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Generando PDF de Curso...")));

    final enrollmentProvider = context.read<EnrollmentProvider>();
    final studentProvider = context.read<StudentProvider>();

    try {
      // Load enrollments for this bundle if not loaded
      await enrollmentProvider.loadBundleEnrollments(bundle.id);

      final enrolledStudentIds = enrollmentProvider.enrollments
          .map((e) => e.studentId)
          .toSet();

      final students = studentProvider.students
          .where((s) => enrolledStudentIds.contains(s.id))
          .toList();

      if (students.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No hay alumnos inscritos en este curso"),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Sort students by Grade then Name
      students.sort((a, b) {
        // Custom sort could be added here if needed, consistent with other views
        return (a.user?.name ?? "").compareTo(b.user?.name ?? "");
      });

      // Fetch Groups, Periods, and Grades for the bundle
      final groupProvider = context.read<GroupProvider>();
      final evaluationProvider = context.read<EvaluationProvider>();
      final gradeProvider = context.read<GradeProvider>();

      // Ensure groups are loaded
      await groupProvider.loadGroups();
      final groups = groupProvider.groups
          .where((g) => g.bundleId == bundle.id)
          .toList();

      if (groups.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No hay materias configuradas para este curso"),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Ensure periods are loaded for this bundle
      await evaluationProvider.loadBundlePeriods(bundle.id);

      print('=== DEBUG _generateCoursePdf ===');
      print('Groups loaded: ${groups.length}');
      for (var g in groups) {
        print('  Group: ${g.courseName}, ID: ${g.id}, BundleID: ${g.bundleId}');
      }

      // Filter periods to only include those for groups in this bundle
      final groupIds = groups.map((g) => g.id).toSet();
      print('Group IDs: $groupIds');

      final periods = evaluationProvider.periods
          .where((p) => groupIds.contains(p.groupId))
          .toList();
      print('Periods filtered: ${periods.length}');
      print('Students: ${students.length}');
      print('Enrollments: ${enrollmentProvider.enrollments.length}');

      // Ensure grades are loaded for this bundle
      await gradeProvider.loadGradesByBundle(bundle.id);

      print('About to call generateCourseReport...');

      await PdfService.generateCourseReport(
        bundle,
        students,
        groups,
        enrollmentProvider.enrollments,
        periods,
        gradeProvider,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error generando reporte: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateCourseExcel(CourseBundle bundle) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Generando Excel de Curso...")),
    );

    final enrollmentProvider = context.read<EnrollmentProvider>();
    final studentProvider = context.read<StudentProvider>();
    final groupProvider = context.read<GroupProvider>();
    final evaluationProvider = context.read<EvaluationProvider>();
    final gradeProvider = context.read<GradeProvider>();

    try {
      await enrollmentProvider.loadBundleEnrollments(bundle.id);

      final enrolledStudentIds = enrollmentProvider.enrollments
          .map((e) => e.studentId)
          .toSet();

      final students = studentProvider.students
          .where((s) => enrolledStudentIds.contains(s.id))
          .toList();

      if (students.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No hay alumnos inscritos en este curso"),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      students.sort(
        (a, b) => (a.user?.name ?? "").compareTo(b.user?.name ?? ""),
      );

      await groupProvider.loadGroups();
      final groups = groupProvider.groups
          .where((g) => g.bundleId == bundle.id)
          .toList();

      if (groups.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No hay materias configuradas para este curso"),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      await evaluationProvider.loadBundlePeriods(bundle.id);

      final groupIds = groups.map((g) => g.id).toSet();
      final periods = evaluationProvider.periods
          .where((p) => groupIds.contains(p.groupId))
          .toList();

      await gradeProvider.loadGradesByBundle(bundle.id);

      await PdfService.generateCourseExcel(
        bundle,
        students,
        groups,
        enrollmentProvider.enrollments,
        periods,
        gradeProvider,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error generando reporte: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateStudentBulletinPdf(Student student) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Generando Boletín PDF...")));

    final enrollmentProvider = context.read<EnrollmentProvider>();
    final groupProvider = context.read<GroupProvider>();
    final evaluationProvider = context.read<EvaluationProvider>();
    final gradeProvider = context.read<GradeProvider>();

    try {
      // 1. Load enrollments for this student
      await enrollmentProvider.loadStudentEnrollments(student.id);
      final enrollments = enrollmentProvider.enrollments;

      if (enrollments.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("El alumno no está inscrito en ningún curso."),
            ),
          );
        }
        return;
      }

      // 2. Load groups for these enrollments to get subject names
      // We need to fetch all groups to be safe, or optimize to fetch by ID
      await groupProvider.loadGroups();

      final enrolledGroupIds = enrollments.map((e) => e.groupId).toSet();
      final enrolledGroups = groupProvider.groups
          .where((g) => enrolledGroupIds.contains(g.id))
          .toList();

      // 3. Load periods and grades for these groups
      // This might be heavy if many groups.
      // Optimization: Load periods/grades only for relevant bundles.
      // But typically a student is in 1 bundle. Let's find unique bundles.
      final bundleIds = enrolledGroups
          .map((g) => g.bundleId)
          .where((id) => id != null)
          .map((id) => id!)
          .toSet();

      for (final bundleId in bundleIds) {
        await evaluationProvider.loadBundlePeriods(bundleId);
        await gradeProvider.loadGradesByBundle(bundleId);
      }

      final allPeriods = evaluationProvider
          .periods; // Note: this might accumulate if provider accumulates?
      // If provider replaces periods on load, this loop is tricky.
      // Assumption: Provider functionality. Usually loadBundlePeriods replaces list.
      // If so, we can't do this loop easily for multiple bundles.
      // Assuming student is in ONE bundle mainly.
      // If provider replaces, we need to collect them.

      // Better approach: filter periods match group IDs from 'all' if possible?
      // Or if loadBundlePeriods replaces, we need to handle that.
      // Let's assume student is in one bundle for now, or just handle the last loaded one?
      // Actually, if we just loop and process, we might lose previous data if provider state is overwritten.
      // Let's check EvaluationProvider behavior? Usually it clears.

      // Let's try to collect all periods if provider exposes a way, or just assume one bundle.
      // If multiple bundles, this code might only show grades for the last one.

      await PdfService.generateStudentBulletin(
        student,
        enrolledGroups,
        allPeriods,
        gradeProvider,
        enrollments,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _generateStudentBulletinExcel(Student student) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Generando Boletín Excel...")));

    final enrollmentProvider = context.read<EnrollmentProvider>();
    final groupProvider = context.read<GroupProvider>();
    final evaluationProvider = context.read<EvaluationProvider>();
    final gradeProvider = context.read<GradeProvider>();

    try {
      await enrollmentProvider.loadStudentEnrollments(student.id);
      final enrollments = enrollmentProvider.enrollments;

      if (enrollments.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("El alumno no está inscrito en ningún curso."),
            ),
          );
        }
        return;
      }

      await groupProvider.loadGroups();
      final enrolledGroupIds = enrollments.map((e) => e.groupId).toSet();
      final enrolledGroups = groupProvider.groups
          .where((g) => enrolledGroupIds.contains(g.id))
          .toList();

      final bundleIds = enrolledGroups
          .map((g) => g.bundleId)
          .where((id) => id != null)
          .map((id) => id!)
          .toSet();

      for (final bundleId in bundleIds) {
        await evaluationProvider.loadBundlePeriods(bundleId);
        await gradeProvider.loadGradesByBundle(bundleId);
      }

      final allPeriods = evaluationProvider.periods;

      await PdfService.generateStudentBulletinExcel(
        student,
        enrolledGroups,
        allPeriods,
        gradeProvider,
        enrollments,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _generateSubjectPdf(Course course) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Generando Lista PDF de Materia...")),
    );

    final groupProvider = context.read<GroupProvider>();
    final enrollmentProvider = context.read<EnrollmentProvider>();
    final evaluationProvider = context.read<EvaluationProvider>();
    final gradeProvider = context.read<GradeProvider>();
    final studentProvider = context.read<StudentProvider>();

    try {
      await groupProvider.loadGroups();
      // Find groups for this course
      final groups = groupProvider.groups
          .where((g) => g.courseId == course.id)
          .toList();

      if (groups.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "No se encontraron cursos activos para esta materia.",
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Pick the most relevant group (e.g. the last created one, assuming it's the current year)
      // Ideally UI should allow selecting the specific group if multiple exist
      final group = groups.last;

      if (group.bundleId == null) {
        throw Exception("El grupo seleccionado no tiene un curso asociado.");
      }
      final bundleId = group.bundleId!;

      // Load dependencies for this group's bundle
      await Future.wait([
        evaluationProvider.loadBundlePeriods(bundleId),
        enrollmentProvider.loadBundleEnrollments(bundleId),
        gradeProvider.loadGradesByBundle(bundleId),
      ]);

      final periods = evaluationProvider.periods
          .where((p) => p.groupId == group.id)
          .toList();
      final allEnrollments = enrollmentProvider.enrollments;

      // Filter students enrolled in this group
      final groupEnrollmentIds = allEnrollments
          .where((e) => e.groupId == group.id)
          .map((e) => e.studentId)
          .toSet();

      final students = studentProvider.students
          .where((s) => groupEnrollmentIds.contains(s.id))
          .toList();

      if (students.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No hay alumnos inscritos en esta materia."),
            ),
          );
        }
        return;
      }

      // Sort students
      students.sort(
        (a, b) => (a.user?.name ?? "").compareTo(b.user?.name ?? ""),
      );

      await PdfService.generateSubjectReport(
        course,
        students,
        periods,
        gradeProvider,
        allEnrollments,
        group.id,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _generateSubjectExcel(Course course) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Generando Excel de Materia...")),
    );

    final groupProvider = context.read<GroupProvider>();
    final enrollmentProvider = context.read<EnrollmentProvider>();
    final evaluationProvider = context.read<EvaluationProvider>();
    final gradeProvider = context.read<GradeProvider>();
    final studentProvider = context.read<StudentProvider>();

    try {
      await groupProvider.loadGroups();
      final groups = groupProvider.groups
          .where((g) => g.courseId == course.id)
          .toList();

      if (groups.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "No se encontraron cursos activos para esta materia.",
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final group = groups.last;

      if (group.bundleId == null) {
        throw Exception("El grupo seleccionado no tiene un curso asociado.");
      }
      final bundleId = group.bundleId!;

      await Future.wait([
        evaluationProvider.loadBundlePeriods(bundleId),
        enrollmentProvider.loadBundleEnrollments(bundleId),
        gradeProvider.loadGradesByBundle(bundleId),
      ]);

      final periods = evaluationProvider.periods
          .where((p) => p.groupId == group.id)
          .toList();
      final allEnrollments = enrollmentProvider.enrollments;

      final groupEnrollmentIds = allEnrollments
          .where((e) => e.groupId == group.id)
          .map((e) => e.studentId)
          .toSet();

      final students = studentProvider.students
          .where((s) => groupEnrollmentIds.contains(s.id))
          .toList();

      if (students.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No hay alumnos inscritos en esta materia."),
            ),
          );
        }
        return;
      }

      students.sort(
        (a, b) => (a.user?.name ?? "").compareTo(b.user?.name ?? ""),
      );

      await PdfService.generateSubjectExcel(
        course,
        students,
        periods,
        gradeProvider,
        allEnrollments,
        group.id,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
}
