import 'package:login_app/domain/entities/final_grade_history.dart';
import 'package:login_app/domain/entities/academic_year_report.dart';

abstract class AcademicYearRepository {
  /// Close a specific group (saves grades to history)
  Future<void> closeGroup(String groupId);

  /// Get all years that have groups
  Future<List<int>> getAllYears();

  /// Get active years (with active groups)
  Future<List<int>> getActiveYears();

  /// Get final grades history for a student
  Future<List<FinalGradeHistory>> getStudentGradesHistory(String studentId);

  /// Get final grades history for a specific year
  Future<List<FinalGradeHistory>> getYearGradesHistory(int year);

  /// Get summary report for a specific year
  Future<AcademicYearReport?> getYearSummary(int year);

  /// Generate PDF report for a year
  Future<String> generatePdfReport(int year);

  /// Generate Excel report for a year
  Future<String> generateExcelReport(int year);

  /// Generate student certificate PDF for a specific year
  Future<String> generateStudentCertificate(String studentId, int year);
}
