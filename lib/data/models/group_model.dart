import '../../domain/entities/group.dart';

class GroupModel extends Group {
  const GroupModel({
    required super.id,
    required super.courseId,
    required super.teacherId,
    required super.year,
    required super.name,
    super.status = 'active',
    super.bundleId,
    super.courseName,
    super.teacherName,
    super.studentCount,
  });

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'],
      courseId: map['course_id'],
      teacherId: map['teacher_id'],
      year: map['year'],
      name: map['name'],
      status: map['status'] ?? 'active',
      bundleId: map['bundle_id'],
      courseName: map['course_name'], // Helper from JOIN
      teacherName: map['teacher_name'], // Helper from JOIN
      studentCount: map['student_count'], // Helper from JOIN
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'course_id': courseId,
      'teacher_id': teacherId,
      'year': year,
      'name': name,
      'status': status,
      'bundle_id': bundleId,
    };
  }

  factory GroupModel.fromEntity(Group group) {
    return GroupModel(
      id: group.id,
      courseId: group.courseId,
      teacherId: group.teacherId,
      year: group.year,
      name: group.name,
      status: group.status,
      bundleId: group.bundleId,
    );
  }
}
