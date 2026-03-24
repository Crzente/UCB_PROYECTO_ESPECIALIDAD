import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/enrollment_provider.dart';
import '../../../providers/grade_provider.dart';
import '../../../providers/evaluation_provider.dart';

class StudentGradesTab extends StatefulWidget {
  const StudentGradesTab({super.key});

  @override
  State<StudentGradesTab> createState() => _StudentGradesTabState();
}

class _StudentGradesTabState extends State<StudentGradesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        // Load ONLY enrollments for this student (we need a new method for this in EnrollmentProvider or reuse existing if capable)
        // For MVP, we might need to filter manually or add 'loadStudentEnrollments'.
        // Assuming we need to add a method to EnrollmentProvider to fetch "My Enrollments".
        context.read<EnrollmentProvider>().loadStudentEnrollments(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final enrollmentProvider = context.watch<EnrollmentProvider>();

    if (enrollmentProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (enrollmentProvider.studentEnrollments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.class_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              "No estás inscrito en ningún curso.",
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: enrollmentProvider.studentEnrollments.length,
      itemBuilder: (context, index) {
        final enrollment = enrollmentProvider.studentEnrollments[index];
        return _StudentCourseCard(enrollment: enrollment);
      },
    );
  }
}

class _StudentCourseCard extends StatefulWidget {
  final dynamic
  enrollment; // Using dynamic for now until we define a proper DTO or reuse Enrollment model
  // Actually, Enrollment model has groupId. We need to fetch Group details + Grades.
  // This is becoming complex. Better strategy:
  // 1. Fetch Enrolled Groups.
  // 2. For each group, fetch Evaluation Periods and My Grades.

  const _StudentCourseCard({required this.enrollment});

  @override
  State<_StudentCourseCard> createState() => _StudentCourseCardState();
}

class _StudentCourseCardState extends State<_StudentCourseCard> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    // Trigger lazy load of grades/periods if expanded?
    // Or load all at once? Let's load on init for simplicity of prototype.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EvaluationProvider>().loadPeriods(widget.enrollment.groupId);
      context.read<GradeProvider>().loadGrades(widget.enrollment.groupId);
    });
  }

  @override
  Widget build(BuildContext context) {
    // We need Group Name. Enrollment entity usually has it joined.
    // If not, we might need a better "EnrolledCourse" model.
    // Let's assume Enrollment entity has 'courseName' and 'groupName' from previous joins.

    final evaluationProvider = context.watch<EvaluationProvider>();
    final gradeProvider = context.watch<GradeProvider>();

    // Filter periods for this group
    final periods = evaluationProvider.periods
        .where((p) => p.groupId == widget.enrollment.groupId)
        .toList();

    // Calculate Final
    double finalScore = 0;

    for (var period in periods) {
      final score = gradeProvider.getScore(widget.enrollment.id, period.id);
      if (score != null) {
        finalScore += score * (period.weight / 100);
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _expanded,
          onExpansionChanged: (val) => setState(() => _expanded = val),
          title: Text(
            widget.enrollment.courseName ??
                "Curso Desconocido", // Need to ensure this exists
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            "Promedio Actual: ${finalScore.toStringAsFixed(1)}",
            style: GoogleFonts.poppins(
              color: finalScore >= 60 ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.book, color: Colors.blue),
          ),
          children: [
            if (periods.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Sin evaluaciones definidas.",
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  children: periods.map((period) {
                    final score = gradeProvider.getScore(
                      widget.enrollment.id,
                      period.id,
                    );
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                period.name,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                "${period.weight}%",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            score != null ? score.toStringAsFixed(1) : "-",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: score != null
                                  ? (score >= 60 ? Colors.green : Colors.red)
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
