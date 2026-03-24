import '../entities/course_bundle.dart';

abstract class CourseBundleRepository {
  Future<List<CourseBundle>> getAllBundles();
  Future<void> createBundle(CourseBundle bundle);
  Future<bool> canDeleteBundle(String id);
  Future<void> deleteBundle(String id);
  Future<CourseBundle?> getBundleById(String id);
}
