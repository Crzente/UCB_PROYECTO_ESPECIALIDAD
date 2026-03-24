import 'package:flutter/material.dart';
import '../../domain/entities/evaluation_period.dart';
import '../../domain/repositories/evaluation_repository.dart';
import '../../domain/repositories/course_repository.dart';
import 'package:uuid/uuid.dart';

class EvaluationProvider extends ChangeNotifier {
  final EvaluationRepository repository;
  final CourseRepository courseRepository;

  List<EvaluationPeriod> _periods = [];
  bool _isLoading = false;

  EvaluationProvider({
    required this.repository,
    required this.courseRepository,
  });

  List<EvaluationPeriod> get periods => _periods;
  bool get isLoading => _isLoading;

  Future<void> loadPeriods(String groupId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _periods = await repository.getPeriodsByGroup(groupId);
    } catch (e) {
      debugPrint("Error loading periods: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadBundlePeriods(String bundleId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _periods = await repository.getPeriodsByBundle(bundleId);
    } catch (e) {
      debugPrint("Error loading bundle periods: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Automatically creates evaluation periods for a group based on the course templates
  Future<void> ensurePeriodsFromTemplates(
    String groupId,
    String courseId,
  ) async {
    final existing = await repository.getPeriodsByGroup(groupId);
    if (existing.isEmpty) {
      final templates = await courseRepository.getEvaluationTemplates(courseId);
      for (var t in templates) {
        await addPeriod(groupId, t.name, t.weight);
      }
      await loadPeriods(groupId);
    }
  }

  Future<void> addPeriod(String groupId, String name, double weight) async {
    final newPeriod = EvaluationPeriod(
      id: const Uuid().v4(),
      groupId: groupId,
      name: name,
      weight: weight,
    );
    await repository.addPeriod(newPeriod);
    // Note: loadPeriods(groupId) is usually called after addPeriod if needed,
    // or by ensurePeriodsFromTemplates
  }

  Future<void> updatePeriod(
    String id,
    String groupId,
    String name,
    double weight,
  ) async {
    final updatedPeriod = EvaluationPeriod(
      id: id,
      groupId: groupId,
      name: name,
      weight: weight,
    );
    await repository.updatePeriod(updatedPeriod);
    await loadPeriods(groupId);
  }

  Future<void> deletePeriod(String id, String groupId) async {
    await repository.deletePeriod(id);
    await loadPeriods(groupId);
  }
}
