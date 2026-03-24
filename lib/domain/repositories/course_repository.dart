import '../entities/course.dart';
import '../entities/evaluation_template.dart';

abstract class CourseRepository {
  Future<List<Course>> getAllCourses();
  Future<void> createCourse(Course course);
  Future<void> updateCourse(Course course);
  Future<bool> canDeleteCourse(String id);
  Future<void> deleteCourse(String id);

  // Custom Templates
  Future<List<EvaluationTemplate>> getEvaluationTemplates(String courseId);
  Future<void> addEvaluationTemplate(
    String courseId,
    String name,
    double weight,
  );
  Future<void> deleteEvaluationTemplate(String templateId);
  Future<void> updateEvaluationTemplate(
    String templateId,
    String name,
    double weight,
  );
}
