import 'package:login_app/domain/entities/final_grade_history.dart';

class FinalGradeHistoryModel extends FinalGradeHistory {
  const FinalGradeHistoryModel({
    required super.id,
    required super.studentId,
    required super.studentName,
    required super.courseId,
    required super.courseName,
    required super.groupId,
    required super.groupName,
    required super.year,
    required super.finalScore,
    required super.status,
    required super.createdAt,
  });

  factory FinalGradeHistoryModel.fromMap(Map<String, dynamic> map) {
    return FinalGradeHistoryModel(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      studentName: map['student_name'] as String,
      courseId: map['course_id'] as String,
      courseName: map['course_name'] as String,
      groupId: map['group_id'] as String,
      groupName: map['group_name'] as String,
      year: map['year'] as int,
      finalScore: map['final_score'] as double,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'student_name': studentName,
      'course_id': courseId,
      'course_name': courseName,
      'group_id': groupId,
      'group_name': groupName,
      'year': year,
      'final_score': finalScore,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
