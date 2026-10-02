import '../../models/learning_activity.dart';

/// Contract for Module 5 — Learning Progress (AGENT.md §4.3).
/// Lesson completion (5.1) lives on [LessonRepository].
abstract class ProgressRepository {
  /// 5.4 View Learning History — completed lessons, newest first.
  Future<List<LearningActivity>> getLearningHistory(String studentId);
}
