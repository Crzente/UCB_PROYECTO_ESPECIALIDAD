import 'package:flutter/material.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/evaluation_template.dart';
import '../../domain/repositories/course_repository.dart';
import 'package:uuid/uuid.dart';

class CourseProvider extends ChangeNotifier {
  final CourseRepository courseRepository;
  List<Course> _courses = [];
  List<EvaluationTemplate> _currentTemplates = [];
  bool _isLoading = false;

  CourseProvider({required this.courseRepository});

  List<Course> get courses => _courses;
  List<EvaluationTemplate> get currentTemplates => _currentTemplates;
  bool get isLoading => _isLoading;

  Future<void> loadCourses() async {
    _isLoading = true;
    notifyListeners();
    try {
      _courses = await courseRepository.getAllCourses();
    } catch (e) {
      debugPrint("Error loading courses: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCourse({
    required String name,
    String? description,
    String? code,
    int credits = 0,
    String type = 'mixed',
    bool isMandatory = true,
    String? teacherId,
  }) async {
    final newCourse = Course(
      id: const Uuid().v4(),
      name: name,
      description: description,
      code: code,
      credits: credits,
      type: type,
      isMandatory: isMandatory,
      teacherId: teacherId,
    );
    await courseRepository.createCourse(newCourse);
    await loadCourses();
  }

  Future<void> updateCourse({
    required String id,
    required String name,
    String? description,
    String? code,
    int credits = 0,
    String type = 'mixed',
    bool isMandatory = true,
    String? teacherId,
  }) async {
    final updatedCourse = Course(
      id: id,
      name: name,
      description: description,
      code: code,
      credits: credits,
      type: type,
      isMandatory: isMandatory,
      teacherId: teacherId,
    );
    await courseRepository.updateCourse(updatedCourse);
    await loadCourses();
  }

  Future<bool> canDeleteCourse(String courseId) async {
    return await courseRepository.canDeleteCourse(courseId);
  }

  Future<void> deleteCourse(String courseId) async {
    try {
      await courseRepository.deleteCourse(courseId);
      await loadCourses();
    } catch (e) {
      debugPrint("Error deleting course: $e");
      rethrow;
    }
  }

  // --- Template Methods ---

  Future<void> loadTemplates(String courseId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentTemplates = await courseRepository.getEvaluationTemplates(
        courseId,
      );
    } catch (e) {
      debugPrint("Error loading templates: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTemplate(String courseId, String name, double weight) async {
    await courseRepository.addEvaluationTemplate(courseId, name, weight);
    await loadTemplates(courseId);
  }

  Future<void> deleteTemplate(String templateId, String courseId) async {
    await courseRepository.deleteEvaluationTemplate(templateId);
    await loadTemplates(courseId);
  }

  Future<void> updateTemplate(
    String templateId,
    String courseId,
    String name,
    double weight,
  ) async {
    await courseRepository.updateEvaluationTemplate(templateId, name, weight);
    await loadTemplates(courseId);
  }
}
