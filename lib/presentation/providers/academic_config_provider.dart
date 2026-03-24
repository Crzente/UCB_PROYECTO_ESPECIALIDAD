import 'package:flutter/material.dart';
import '../../data/repositories/academic_config_repository_impl.dart';
import '../../domain/entities/academic_period_config.dart';

class AcademicConfigProvider extends ChangeNotifier {
  final AcademicConfigRepositoryImpl repository;

  List<AcademicPeriodConfig> _config = [];
  bool _isLoading = false;

  AcademicConfigProvider({required this.repository});

  List<AcademicPeriodConfig> get config => _config;
  // Alias for compatibility if needed, or update screens to use config
  List<AcademicPeriodConfig> get configs => _config;

  bool get isLoading => _isLoading;

  Future<void> loadConfig() async {
    _isLoading = true;
    notifyListeners();
    try {
      _config = await repository.getActiveConfig();
    } catch (e) {
      debugPrint("Error loading academic config: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setBimesters() async {
    _isLoading = true;
    notifyListeners();
    await repository.setBimestersConfig();
    await loadConfig();
  }

  Future<void> setTrimesters() async {
    _isLoading = true;
    notifyListeners();
    await repository.setTrimestersConfig();
    await loadConfig();
  }

  Future<void> updateConfig(String id, String name, double weight) async {
    _isLoading = true;
    notifyListeners();
    try {
      await repository.updateConfig(id, name, weight);
      await loadConfig();
    } catch (e) {
      debugPrint("Error updating config: $e");
      _isLoading = false;
      notifyListeners();
    }
  }
}
