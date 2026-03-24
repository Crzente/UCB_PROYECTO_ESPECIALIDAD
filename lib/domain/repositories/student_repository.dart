import '../entities/student.dart';

abstract class StudentRepository {
  Future<List<Student>> getStudents();
  Future<Student?> getStudentById(String id);
  Future<Student?> getStudentByUserId(String userId);
  Future<void> createStudent(Student student);
  Future<void> updateStudent(Student student);
  Future<void> deleteStudent(String id);
}
