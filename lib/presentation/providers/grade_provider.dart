import 'package:flutter/material.dart';
import '../../domain/entities/grade.dart';
import '../../domain/repositories/grade_repository.dart';
import 'package:uuid/uuid.dart';

class GradeProvider extends ChangeNotifier {
  final GradeRepository repository;

  List<Grade> _grades = [];
  bool _isLoading = false;

  GradeProvider({required this.repository});

  List<Grade> get grades => _grades;
  bool get isLoading => _isLoading;

  Future<void> loadGrades(String groupId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final loaded = await repository.getGradesByGroup(groupId);
      _grades = _deduplicate(loaded);
    } catch (e) {
      debugPrint("Error loading grades: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadGradesByBundle(String bundleId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final loaded = await repository.getGradesByBundle(bundleId);
      _grades = _deduplicate(loaded);
    } catch (e) {
      debugPrint("Error loading bundle grades: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Grade> _deduplicate(List<Grade> list) {
    // Keep only the last one for each pair if duplicates exist in DB
    final Map<String, Grade> unique = {};
    for (var g in list) {
      unique["${g.enrollmentId}-${g.evaluationPeriodId}"] = g;
    }
    return unique.values.toList();
  }

  Future<void> updateGrade(
    String enrollmentId,
    String periodId,
    double score,
  ) async {
    // Find if we already have it locally
    final existingIndex = _grades.indexWhere(
      (g) => g.enrollmentId == enrollmentId && g.evaluationPeriodId == periodId,
    );

    final grade = Grade(
      id: existingIndex >= 0 ? _grades[existingIndex].id : const Uuid().v4(),
      enrollmentId: enrollmentId,
      evaluationPeriodId: periodId,
      score: score,
    );

    // Save to DB (Repository now handles semantic deduplication too)
    await repository.saveGrade(grade);

    // Update state
    if (existingIndex >= 0) {
      _grades[existingIndex] = grade;
    } else {
      _grades.add(grade);
    }
    notifyListeners();
  }

  double? getScore(String enrollmentId, String periodId) {
    try {
      return _grades
          .firstWhere(
            (g) =>
                g.enrollmentId == enrollmentId &&
                g.evaluationPeriodId == periodId,
          )
          .score;
    } catch (_) {
      return null;
    }
  }
}
