import '../entities/evaluation_period.dart';

abstract class EvaluationRepository {
  Future<List<EvaluationPeriod>> getPeriodsByGroup(String groupId);
  Future<List<EvaluationPeriod>> getPeriodsByBundle(String bundleId); // New
  Future<void> addPeriod(EvaluationPeriod period);
  Future<void> updatePeriod(EvaluationPeriod period);
  Future<void> deletePeriod(String id);
}
