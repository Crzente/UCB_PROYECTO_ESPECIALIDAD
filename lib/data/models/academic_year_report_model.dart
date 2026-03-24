import 'dart:convert';
import 'package:login_app/domain/entities/academic_year_report.dart';

class AcademicYearReportModel extends AcademicYearReport {
  const AcademicYearReportModel({
    required super.id,
    required super.year,
    required super.generatedAt,
    required super.totalStudents,
    required super.totalCourses,
    required super.totalGroups,
    super.reportData,
  });

  factory AcademicYearReportModel.fromMap(Map<String, dynamic> map) {
    return AcademicYearReportModel(
      id: map['id'] as String,
      year: map['year'] as int,
      generatedAt: DateTime.parse(map['generated_at'] as String),
      totalStudents: map['total_students'] as int,
      totalCourses: map['total_courses'] as int,
      totalGroups: map['total_groups'] as int,
      reportData: map['report_data'] != null
          ? jsonDecode(map['report_data'] as String) as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'year': year,
      'generated_at': generatedAt.toIso8601String(),
      'total_students': totalStudents,
      'total_courses': totalCourses,
      'total_groups': totalGroups,
      'report_data': reportData != null ? jsonEncode(reportData) : null,
    };
  }
}
