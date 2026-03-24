import 'package:flutter/material.dart';
import '../../domain/entities/teacher.dart';
import '../../domain/repositories/teacher_repository.dart';

class TeacherProvider extends ChangeNotifier {
  final TeacherRepository teacherRepository;

  List<Teacher> _teachers = [];
  bool _isLoading = false;

  TeacherProvider({required this.teacherRepository});

  List<Teacher> get teachers => _teachers;
  bool get isLoading => _isLoading;

  Future<void> loadTeachers() async {
    _isLoading = true;
    notifyListeners();
    try {
      _teachers = await teacherRepository.getTeachers();
    } catch (e) {
      debugPrint("Error loading teachers: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createTeacher(Teacher teacher) async {
    await teacherRepository.createTeacher(teacher);
    await loadTeachers();
  }

  Future<void> updateTeacher(Teacher teacher) async {
    await teacherRepository.updateTeacher(teacher);
    await loadTeachers();
  }

  Future<void> deleteTeacher(String id) async {
    await teacherRepository.deleteTeacher(id);
    await loadTeachers();
  }
}
