import '../entities/group.dart';

abstract class GroupRepository {
  Future<List<Group>> getAllGroups();
  Future<List<Group>> getGroupsByCourse(String courseId);
  Future<List<String>> getUniqueGroupNames();
  Future<void> createGroup(Group group);
  Future<void> updateGroup(Group group);
  Future<bool> canDeleteGroup(String id);
  Future<void> deleteGroup(String id);
}
