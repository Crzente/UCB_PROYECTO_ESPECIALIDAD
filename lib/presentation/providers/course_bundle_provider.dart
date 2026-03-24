import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/course_bundle.dart';
import '../../domain/repositories/course_bundle_repository.dart';

class CourseBundleProvider extends ChangeNotifier {
  final CourseBundleRepository repository;

  List<CourseBundle> _bundles = [];
  bool _isLoading = false;

  CourseBundleProvider({required this.repository});

  List<CourseBundle> get bundles => _bundles;
  bool get isLoading => _isLoading;

  Future<void> loadBundles() async {
    _isLoading = true;
    notifyListeners();
    try {
      _bundles = await repository.getAllBundles();
    } catch (e) {
      debugPrint("Error loading bundles: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> createBundle(String name, int academicYear) async {
    _isLoading = true;
    notifyListeners();
    try {
      final id = const Uuid().v4();
      final newBundle = CourseBundle(
        id: id,
        name: name,
        academicYear: academicYear,
        createdAt: DateTime.now(),
      );
      await repository.createBundle(newBundle);
      await loadBundles();
      return id;
    } catch (e) {
      debugPrint("Error creating bundle: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> canDeleteBundle(String id) async {
    return await repository.canDeleteBundle(id);
  }

  Future<void> deleteBundle(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await repository.deleteBundle(id);
      await loadBundles();
    } catch (e) {
      debugPrint("Error deleting bundle: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
