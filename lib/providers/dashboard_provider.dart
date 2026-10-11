import 'package:flutter/foundation.dart';

import '../data/repositories/dashboard_repository.dart';
import '../models/student_dashboard.dart';

/// State holder for Module 7 — Student Dashboard (7.1–7.4).
class DashboardProvider extends ChangeNotifier {
  DashboardProvider({required DashboardRepository repo}) : _repository = repo;

  final DashboardRepository _repository;

  StudentDashboard? dashboard;
  bool isLoading = false;
  String? error;

  /// [silent] refreshes in the background: no spinner, and the current data
  /// stays on screen if the request fails.
  Future<void> load(String studentId, {bool silent = false}) async {
    if (silent) {
      try {
        dashboard = await _repository.getDashboard(studentId);
        error = null;
        notifyListeners();
      } on Exception catch (_) {}
      return;
    }
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      dashboard = await _repository.getDashboard(studentId);
    } on Exception catch (e) {
      error = 'Could not load your dashboard. $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
