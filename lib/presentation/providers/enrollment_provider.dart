import 'package:flutter/material.dart';
import '../../domain/entities/enrollment.dart';
import '../../domain/entities/grade.dart';
import '../../domain/repositories/enrollment_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/repositories/group_repository.dart';
import '../../domain/repositories/evaluation_repository.dart';
import '../../domain/repositories/grade_repository.dart';
import '../../domain/entities/user.dart';
import 'package:uuid/uuid.dart';

class EnrollmentProvider extends ChangeNotifier {
  final EnrollmentRepository enrollmentRepository;
  final UserRepository userRepository;
  final GroupRepository groupRepository;
  final EvaluationRepository evaluationRepository;
  final GradeRepository gradeRepository;

  List<Enrollment> _enrollments = [];
  List<User> _availableStudents = [];
  bool _isLoading = false;

  EnrollmentProvider({
    required this.enrollmentRepository,
    required this.userRepository,
    required this.groupRepository,
    required this.evaluationRepository,
    required this.gradeRepository,
  });

  List<Enrollment> get enrollments => _enrollments;
  List<Enrollment> _studentEnrollments =
      []; // New list for student specific enrollments
  List<Enrollment> get studentEnrollments => _studentEnrollments;
  List<User> get availableStudents => _availableStudents;
  bool get isLoading => _isLoading;

  Future<void> loadEnrollments(String groupId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _enrollments = await enrollmentRepository.getEnrollmentsByGroup(groupId);
    } catch (e) {
      debugPrint("Error loading enrollments: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAvailableStudents() async {
    try {
      _availableStudents = await userRepository.getUsersByRole('student');
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading students: $e");
    }
  }

  // OLD METHOD: Keep for compatibility if needed, but forbidden by new rules
  Future<void> enrollStudent(String groupId, String studentId) async {
    debugPrint("Warning: enrollStudent (single group) is deprecated.");
    final newEnrollment = Enrollment(
      id: const Uuid().v4(),
      groupId: groupId,
      studentId: studentId,
    );
    await enrollmentRepository.enrollStudent(newEnrollment);
    await loadEnrollments(groupId);
  }

  /// NEW FLOW: Enroll student in a Course (all its groups)
  Future<void> enrollStudentInCourse(String courseId, String studentId) async {
    // This looks for groups by courseId (Subject).
    // If we want bundle enrollment by "Group Name" (e.g. 1A), use enrollStudentInAcademicBundle
    debugPrint(
      "Warning: enrollStudentInCourse uses Subject-based logic. Switch to enrollStudentInAcademicBundle if grouping by name.",
    );
    await enrollStudentInAcademicBundle(courseId, studentId);
  }

  /// REAL BUNDLE ENROLLMENT: Enroll in all groups belonging to the specific bundle
  Future<void> enrollStudentInAcademicBundle(
    String bundleId,
    String studentId,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      // 1. Get Bundle Info
      final int? academicYear = await enrollmentRepository.getBundleYear(
        bundleId,
      );
      if (academicYear == null) throw Exception("Curso no encontrado.");

      // 2. Check if student is already enrolled in this YEAR
      final bool alreadyEnrolled = await enrollmentRepository
          .isStudentEnrolledInYear(studentId, academicYear);
      if (alreadyEnrolled) {
        throw Exception(
          "El alumno ya está inscrito en un curso para la gestión $academicYear. Debe desinscribirlo primero.",
        );
      }

      // 3. Save bundle enrollment
      await enrollmentRepository.addStudentToBundle(studentId, bundleId);

      // 4. Get all groups that belong to this bundle ID and enroll locally
      final allGroups = await groupRepository.getAllGroups();
      final groups = allGroups.where((g) => g.bundleId == bundleId).toList();


      for (var group in groups) {
        final enrollmentId = const Uuid().v4();
        final enrollment = Enrollment(
          id: enrollmentId,
          groupId: group.id,
          studentId: studentId,
        );
        await enrollmentRepository.enrollStudent(enrollment);

        // 4. Create base grade records
        final periods = await evaluationRepository.getPeriodsByGroup(group.id);
        for (var period in periods) {
          final grade = Grade(
            id: const Uuid().v4(),
            enrollmentId: enrollmentId,
            evaluationPeriodId: period.id,
            score: null,
          );
          await gradeRepository.saveGrade(grade);
        }
      }
    } catch (e) {
      debugPrint("Error enrolling student in bundle: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> unenrollStudentFromBundle(
    String studentId,
    String bundleId,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      await enrollmentRepository.removeStudentFromBundle(studentId, bundleId);
      await loadStudentEnrollments(studentId);
    } catch (e) {
      debugPrint("Error unenrolling student from bundle: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStudentEnrollments(String studentId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _studentEnrollments = await enrollmentRepository.getEnrollmentsByStudent(
        studentId,
      );
    } catch (e) {
      debugPrint("Error loading student enrollments: $e");
      _studentEnrollments = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadBundleEnrollments(String bundleId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _enrollments = await enrollmentRepository.getEnrollmentsByBundle(
        bundleId,
      );
    } catch (e) {
      debugPrint("Error loading bundle enrollments: $e");
      _enrollments = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// AUTO-ENROLLMENT: When a new Subject (Group) is created in a Bundle (Course Name),
  /// automatically enroll all students who are already part of that Bundle.
  Future<void> autoEnrollStudentsInNewGroup(dynamic newGroup) async {
    // newGroup is of type Group. using dynamic to avoid import issues if Group not imported here,
    // but better to rely on imports.
    // Logic:
    // 1. Find all other groups that share the same `name` (Bundle).
    // 2. Identify all students currently enrolled in ANY of those groups.
    // 3. Enroll those students in this `newGroup`.

    // Safety check: Only if group is Active (if group has status field)
    // Assuming 'active' is default or checked before calling this.

    _isLoading = true;
    notifyListeners();
    try {
      debugPrint(
        "Auto-enrolling students for new group: ${newGroup.courseName ?? newGroup.id} (Bundle ID: ${newGroup.bundleId})",
      );

      if (newGroup.bundleId == null) {
        debugPrint("No bundle configured for this group. No students to auto-enroll.");
        return;
      }

      // 1. Collect all students enrolled in this bundle.
      final bundleEnrollments = await enrollmentRepository.getEnrollmentsByBundle(
        newGroup.bundleId!,
      );
      
      final Set<String> studentIdsToEnroll = bundleEnrollments.map((e) => e.studentId).toSet();


      debugPrint(
        "Found ${studentIdsToEnroll.length} students to enrollment in new subject.",
      );

      // 3. Enroll them in the NEW group
      for (var studentId in studentIdsToEnroll) {
        try {
          // Check if already enrolled (paranoia check)
          // Since it's a new group, should be empty, but let's be safe.
          // Actually, we can just try enroll.

          final enrollmentId = const Uuid().v4();
          final enrollment = Enrollment(
            id: enrollmentId,
            groupId: newGroup.id,
            studentId: studentId,
          );
          await enrollmentRepository.enrollStudent(enrollment);

          // 4. Create base grade records for this new group
          final periods = await evaluationRepository.getPeriodsByGroup(
            newGroup.id,
          );
          for (var period in periods) {
            final grade = Grade(
              id: const Uuid().v4(),
              enrollmentId: enrollmentId,
              evaluationPeriodId: period.id,
              score: null,
            );
            await gradeRepository.saveGrade(grade);
          }
        } catch (e) {
          debugPrint("Error auto-enrolling student $studentId: $e");
          // Continue with next student
        }
      }
    } catch (e) {
      debugPrint("Critical error in autoEnrollStudentsInNewGroup: $e");
      // Don't rethrow to avoid blocking the group creation UI?
      // User said "The system must...". So maybe we should show error.
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> unenrollStudent(String enrollmentId) async {
    await enrollmentRepository.removeStudent(enrollmentId);
  }

  Future<void> updateEnrollmentStatus(
    String enrollmentId,
    String status,
  ) async {
    await enrollmentRepository.updateEnrollmentStatus(enrollmentId, status);
  }

  Future<void> updateStudentStatusInBundle(
    String studentId,
    String bundleId,
    String newStatus,
  ) async {
    debugPrint(
      "Updating student status in bundle: studentId=$studentId, bundleId=$bundleId, newStatus=$newStatus",
    );
    _isLoading = true;
    notifyListeners();
    try {
      // Use atomic update in repository
      await enrollmentRepository.updateStudentStatusByBundle(
        studentId,
        bundleId,
        newStatus,
      );

      debugPrint("Status updated successfully in DB. Refreshing state...");

      // 4. Refresh local state for both student view and bundle view
      await loadStudentEnrollments(studentId);
      await loadBundleEnrollments(bundleId);

      debugPrint(
        "Refresco completo: Alumno(${_studentEnrollments.length}) y Curso(${_enrollments.length})",
      );
    } catch (e) {
      debugPrint("Error updating student status in bundle: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
