import '../../domain/entities/course.dart';

class CourseModel extends Course {
  const CourseModel({
    required super.id,
    required super.name,
    super.description,
    super.code,
    super.credits = 0,
    super.type = 'mixed',
    super.isMandatory = true,
    super.teacherId,
  });

  factory CourseModel.fromMap(Map<String, dynamic> map) {
    return CourseModel(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      code: map['code'],
      credits: map['credits'] ?? 0,
      type: map['type'] ?? 'mixed',
      isMandatory: map['is_mandatory'] == 1, // Store as INTEGER (0/1) in SQLite
      teacherId: map['teacher_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'code': code,
      'credits': credits,
      'type': type,
      'is_mandatory': isMandatory ? 1 : 0,
      'teacher_id': teacherId,
    };
  }

  factory CourseModel.fromEntity(Course course) {
    return CourseModel(
      id: course.id,
      name: course.name,
      description: course.description,
      code: course.code,
      credits: course.credits,
      type: course.type,
      isMandatory: course.isMandatory,
      teacherId: course.teacherId,
    );
  }
}
