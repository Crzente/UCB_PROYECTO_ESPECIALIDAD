class Enrollment {
  final String id;
  final String studentId;
  final String groupId;
  final String? studentName;
  final String? groupName;
  final String? courseName;
  final String? bundleId;
  final String? bundleName;
  final int? academicYear;
  final String? grade;
  final String? specialty;
  final String? graduationYear;
  final int? courseSeniority;
  final String status; // 'En curso', 'Suspendido', 'Retirado', 'Finalizado'

  const Enrollment({
    required this.id,
    required this.studentId,
    required this.groupId,
    this.studentName,
    this.groupName,
    this.courseName,
    this.bundleId,
    this.bundleName,
    this.academicYear,
    this.grade,
    this.specialty,
    this.graduationYear,
    this.courseSeniority,
    this.status = 'En curso',
  });
}
