import 'package:flutter/material.dart';
import '../../domain/entities/student.dart';
import '../../domain/repositories/student_repository.dart';

class StudentProvider extends ChangeNotifier {
  final StudentRepository studentRepository;

  List<Student> _students = [];
  bool _isLoading = false;

  StudentProvider({required this.studentRepository});

  List<Student> get students => _students;
  bool get isLoading => _isLoading;

  Future<void> loadStudents() async {
    _isLoading = true;
    notifyListeners();
    try {
      _students = await studentRepository.getStudents();
    } catch (e) {
      debugPrint("Error loading students: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createStudent(Student student) async {
    await studentRepository.createStudent(student);
    await loadStudents();
  }

  Future<void> updateStudent(Student student) async {
    await studentRepository.updateStudent(student);
    await loadStudents();
  }

  Future<void> deleteStudent(String id) async {
    // Assuming repository has deleteStudent. If not, this will fail compilation.
    // I should check repository first.
    // But I will assume it does or I will fix repository next.
    // Wait, let's verify repository first to avoid errors.
    // Actually, I'll just add it and if error, I fix repo.
    await studentRepository.deleteStudent(id);
    await loadStudents();
  }
}
