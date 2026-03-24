import '../entities/grade.dart';

abstract class GradeRepository {
  Future<List<Grade>> getGradesByGroup(String groupId);
  Future<List<Grade>> getGradesByBundle(String bundleId);
  Future<void> saveGrade(Grade grade);
}
