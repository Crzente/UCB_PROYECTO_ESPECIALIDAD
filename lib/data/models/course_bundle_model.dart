import '../../domain/entities/course_bundle.dart';

class CourseBundleModel extends CourseBundle {
  const CourseBundleModel({
    required super.id,
    required super.name,
    required super.academicYear,
    required super.createdAt,
    super.isActive = true,
  });

  factory CourseBundleModel.fromMap(Map<String, dynamic> map) {
    return CourseBundleModel(
      id: map['id'],
      name: map['name'],
      academicYear: map['academic_year'],
      createdAt: DateTime.parse(map['created_at']),
      isActive: map['is_active'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'academic_year': academicYear,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  factory CourseBundleModel.fromEntity(CourseBundle bundle) {
    return CourseBundleModel(
      id: bundle.id,
      name: bundle.name,
      academicYear: bundle.academicYear,
      createdAt: bundle.createdAt,
      isActive: bundle.isActive,
    );
  }
}
