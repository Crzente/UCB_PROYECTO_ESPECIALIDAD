import 'package:flutter/foundation.dart';
import 'package:login_app/data/repositories/academic_year_repository_impl.dart';
import 'package:login_app/domain/entities/final_grade_history.dart';
import 'package:login_app/domain/entities/academic_year_report.dart';
import 'package:login_app/domain/repositories/academic_year_repository.dart';

class AcademicYearProvider with ChangeNotifier {
  final AcademicYearRepository _repository = AcademicYearRepositoryImpl();

  List<int> _allYears = [];
  List<int> _activeYears = [];
  List<FinalGradeHistory> _gradesHistory = [];
  AcademicYearReport? _currentReport;
  bool _isLoading = false;
  String? _error;

  List<int> get allYears => _allYears;
  List<int> get activeYears => _activeYears;
  List<FinalGradeHistory> get gradesHistory => _gradesHistory;
  AcademicYearReport? get currentReport => _currentReport;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadYears() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allYears = await _repository.getAllYears();
      _activeYears = await _repository.getActiveYears();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> closeGroup(String groupId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.closeGroup(groupId);
      await loadYears();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadStudentGradesHistory(String studentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _gradesHistory = await _repository.getStudentGradesHistory(studentId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadYearGradesHistory(int year) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _gradesHistory = await _repository.getYearGradesHistory(year);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadYearReport(int year) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentReport = await _repository.getYearSummary(year);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> generatePdfReport(int year) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final filePath = await _repository.generatePdfReport(year);
      return filePath;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> generateExcelReport(int year) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final filePath = await _repository.generateExcelReport(year);
      return filePath;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> generateStudentCertificate(String studentId, int year) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final filePath = await _repository.generateStudentCertificate(
        studentId,
        year,
      );
      return filePath;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
