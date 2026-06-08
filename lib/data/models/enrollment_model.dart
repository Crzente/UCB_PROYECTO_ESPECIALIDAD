import '../../domain/entities/enrollment.dart';

class EnrollmentModel extends Enrollment {
  const EnrollmentModel({
    required super.id,
    required super.studentId,
    required super.groupId,
    super.studentName,
    super.groupName,
    super.courseName,
    super.bundleId,
    super.bundleName,
    super.academicYear,
    super.grade,
    super.specialty,
    super.graduationYear,
    super.courseSeniority,
    super.status = 'En curso',
  });

  factory EnrollmentModel.fromMap(Map<String, dynamic> map) {
    return EnrollmentModel(
      id: map['id'],
      studentId: map['student_id'],
      groupId: map['group_id'],
      studentName: map['student_name'],
      groupName: map['group_name'],
      courseName: map['course_name'],
      bundleId: map['bundle_id'],
      bundleName: map['bundle_name'],
      academicYear: map['academic_year'],
      grade: map['grade'],
      specialty: map['specialty'],
      graduationYear: map['graduation_year'],
      courseSeniority: map['course_seniority'],
      status: map['status'] ?? 'En curso',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'group_id': groupId,
      'status': status,
    };
  }

  factory EnrollmentModel.fromEntity(Enrollment enrollment) {
    return EnrollmentModel(
      id: enrollment.id,
      studentId: enrollment.studentId,
      groupId: enrollment.groupId,
      status: enrollment.status,
    );
  }
}
