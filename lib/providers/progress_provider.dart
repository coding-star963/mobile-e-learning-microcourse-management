import 'package:flutter/foundation.dart';

import '../data/repositories/progress_repository.dart';
import '../models/learning_activity.dart';

/// State holder for Module 5 — Learning Progress (5.4 Learning History).
class ProgressProvider extends ChangeNotifier {
  ProgressProvider({required ProgressRepository repo}) : _repository = repo;

  final ProgressRepository _repository;

  List<LearningActivity> history = [];
  bool isLoading = false;
  String? error;

  /// 5.4 View Learning History
  Future<void> loadHistory(String studentId) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      history = await _repository.getLearningHistory(studentId);
    } on Exception catch (e) {
      error = 'Could not load your learning history. $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
