class AcademicYearReport {
  final String id;
  final int year;
  final DateTime generatedAt;
  final int totalStudents;
  final int totalCourses;
  final int totalGroups;
  final Map<String, dynamic>? reportData;

  const AcademicYearReport({
    required this.id,
    required this.year,
    required this.generatedAt,
    required this.totalStudents,
    required this.totalCourses,
    required this.totalGroups,
    this.reportData,
  });
}
