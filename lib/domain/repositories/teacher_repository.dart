import '../entities/teacher.dart';

abstract class TeacherRepository {
  Future<List<Teacher>> getTeachers();
  Future<Teacher?> getTeacherById(String id);
  Future<Teacher?> getTeacherByUserId(String userId);
  Future<void> createTeacher(Teacher teacher);
  Future<void> updateTeacher(Teacher teacher);
  Future<void> deleteTeacher(String id);
}
