class Group {
  final String id;
  final String courseId;
  final String teacherId;
  final int year;
  final String name;
  final String status; // 'active' | 'archived'

  // UI Helpers (fetched via JOINs)
  final String? courseName;
  final String? teacherName;
  final int? studentCount;

  const Group({
    required this.id,
    required this.courseId,
    required this.teacherId,
    required this.year,
    required this.name,
    this.status = 'active',
    this.bundleId,
    this.courseName,
    this.teacherName,
    this.studentCount,
  });

  // Optional: Add bundleId field
  final String? bundleId;
}
