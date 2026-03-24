import 'package:equatable/equatable.dart';

class CourseBundle extends Equatable {
  final String id;
  final String name;
  final int academicYear;
  final DateTime createdAt;
  final bool isActive;

  const CourseBundle({
    required this.id,
    required this.name,
    required this.academicYear,
    required this.createdAt,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, name, academicYear, createdAt, isActive];
}
