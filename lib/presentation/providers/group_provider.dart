import 'package:flutter/material.dart';
import '../../domain/entities/group.dart';
import '../../domain/repositories/group_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/entities/user.dart';
import 'package:uuid/uuid.dart';
import '../../presentation/providers/enrollment_provider.dart';

class GroupProvider extends ChangeNotifier {
  final GroupRepository groupRepository;
  final UserRepository userRepository; // To fetch teachers
  EnrollmentProvider enrollmentProvider; // Injected to trigger auto-enrollment

  List<Group> _groups = [];
  List<User> _teachers = [];
  bool _isLoading = false;

  GroupProvider({
    required this.groupRepository,
    required this.userRepository,
    required this.enrollmentProvider,
  });

  List<Group> get groups => _groups;
  List<User> get teachers => _teachers;
  bool get isLoading => _isLoading;

  Future<void> loadGroups() async {
    _isLoading = true;
    notifyListeners();
    try {
      _groups = await groupRepository.getAllGroups();
    } catch (e) {
      debugPrint("Error loading groups: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTeachers() async {
    try {
      _teachers = await userRepository.getUsersByRole('teacher');
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading teachers: $e");
    }
  }

  Future<String> addGroup(
    String courseId,
    String teacherId,
    String name,
    int year, {
    String? bundleId,
  }) async {
    final id = const Uuid().v4();
    final newGroup = Group(
      id: id,
      courseId: courseId,
      teacherId: teacherId,
      year: year,
      name: name,
      bundleId: bundleId,
    );
    debugPrint("Provider: Adding new group to bundle $bundleId. Name: $name");
    await groupRepository.createGroup(newGroup);
    debugPrint("Provider: Group saved. Starting auto-enrollment...");

    // AUTO-ENROLL existing students of the same bundle ("Curso")
    try {
      await enrollmentProvider.autoEnrollStudentsInNewGroup(newGroup);
    } catch (e) {
      debugPrint("Warning: Auto-enrollment failed for new group: $e");
      // We don't block the UI, but we log it.
    }

    await loadGroups();
    debugPrint(
      "Provider: Groups reloaded. Count: ${_groups.length}. Searching for bundleId: $bundleId",
    );
    return id;
  }

  Future<void> loadTeacherGroups(String teacherId) async {
    _isLoading = true;
    notifyListeners();
    try {
      // For now we filter locally, but in future should be a repo method getGroupsByTeacher
      final allGroups = await groupRepository.getAllGroups();
      _groups = allGroups.where((g) => g.teacherId == teacherId).toList();
    } catch (e) {
      debugPrint("Error loading teacher groups: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateGroupTeacher(String groupId, String teacherId) async {
    final group = _groups.firstWhere((g) => g.id == groupId);
    final updatedGroup = Group(
      id: group.id,
      courseId: group.courseId,
      teacherId: teacherId,
      year: group.year,
      name: group.name,
      status: group.status,
      bundleId: group.bundleId,
    );
    await groupRepository.updateGroup(updatedGroup);
    await loadGroups();
  }

  Future<bool> canDeleteGroup(String groupId) async {
    return await groupRepository.canDeleteGroup(groupId);
  }

  Future<void> deleteGroup(String groupId) async {
    try {
      await groupRepository.deleteGroup(groupId);
      await loadGroups();
    } catch (e) {
      debugPrint("Error deleting group: $e");
      rethrow;
    }
  }
}
