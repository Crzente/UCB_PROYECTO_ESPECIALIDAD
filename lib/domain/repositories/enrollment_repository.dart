import '../entities/enrollment.dart';

abstract class EnrollmentRepository {
  Future<List<Enrollment>> getEnrollmentsByGroup(String groupId);
  Future<void> enrollStudent(Enrollment enrollment);
  Future<List<Enrollment>> getEnrollmentsByStudent(String studentId);
  Future<List<Enrollment>> getEnrollmentsByBundle(String bundleId); // New
  Future<void> removeStudent(String id);
  Future<bool> isStudentEnrolledInYear(String studentId, int year);
  Future<void> removeStudentFromBundle(String studentId, String bundleId);
  Future<int?> getBundleYear(String bundleId);
  Future<void> updateEnrollmentStatus(String enrollmentId, String status);
  Future<void> updateStudentStatusByBundle(
    String studentId,
    String bundleId,
    String status,
  );
  Future<void> addStudentToBundle(String studentId, String bundleId);
}
