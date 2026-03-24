class FinalGradeHistory {
  final String id;
  final String studentId;
  final String studentName;
  final String courseId;
  final String courseName;
  final String groupId;
  final String groupName;
  final int year;
  final double finalScore;
  final String status; // 'approved' | 'failed' | 'incomplete'
  final DateTime createdAt;

  const FinalGradeHistory({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.courseId,
    required this.courseName,
    required this.groupId,
    required this.groupName,
    required this.year,
    required this.finalScore,
    required this.status,
    required this.createdAt,
  });

  bool get isApproved => status == 'approved';
  bool get isFailed => status == 'failed';
}
