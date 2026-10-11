import 'package:flutter/foundation.dart';
import '../data/repositories/lesson_repository.dart';
import '../models/lesson.dart';

/// Provider for Module 4 (Lesson & Learning Content, 4.1–4.6)
/// and Module 5 (5.1 Track Lesson Completion).
class LessonProvider extends ChangeNotifier {
  LessonProvider({required this.repo});

  final LessonRepository repo;

  final Map<String, List<Lesson>> _courseLessons = {};
  final Map<String, Lesson> _lessonDetails = {};
  /// Completed lessons for the signed-in student, seeded from the server.
  final Set<String> _completedLessonIds = {};

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Set<String> get completedLessonIds => _completedLessonIds;

  List<Lesson> lessonsFor(String courseId) =>
      _courseLessons[courseId] ?? const [];

  Lesson? cachedLesson(String lessonId) => _lessonDetails[lessonId];

  bool isCompleted(String lessonId) => _completedLessonIds.contains(lessonId);

  /// Background refresh of every course whose lessons have been opened, so
  /// new, edited, locked or scheduled lessons appear without a manual refresh.
  /// The list includes each lesson's resources, so open lessons update too.
  Future<void> refreshLoaded() async {
    for (final courseId in _courseLessons.keys.toList()) {
      try {
        final lessons = await repo.getLessonsForCourse(courseId);
        _courseLessons[courseId] = lessons;
        for (final l in lessons) {
          _lessonDetails[l.id] = l;
          _rememberCompletion(l);
        }
        notifyListeners();
      } catch (_) {
        // Keep the current lessons; the next refresh retries.
      }
    }
  }

  /// 4.1 View Course Lessons
  Future<void> loadLessons(String courseId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final lessons = await repo.getLessonsForCourse(courseId);
      _courseLessons[courseId] = lessons;
      for (final l in lessons) {
        _lessonDetails[l.id] = l;
        _rememberCompletion(l);
      }
    } catch (e) {
      _error = 'Failed to load lessons: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 4.2 View Lesson Details
  Future<Lesson?> loadLessonDetails(String courseId, String lessonId) async {
    final cached = _lessonDetails[lessonId];
    if (cached != null && cached.resources.isNotEmpty) {
      return cached;
    }

    try {
      final lesson = await repo.getLessonDetails(courseId, lessonId);
      if (lesson != null) {
        _lessonDetails[lessonId] = lesson;
        _rememberCompletion(lesson);
        notifyListeners();
      }
      return lesson;
    } catch (e) {
      _error = 'Failed to load lesson details: $e';
      notifyListeners();
      return cached;
    }
  }

  /// 5.1 Track Lesson Completion — updates the UI immediately, saves to the
  /// repository, and reverts (returning false, with [error] set) if saving fails.
  Future<bool> toggleLessonCompleted(String lessonId) async {
    final completed = !_completedLessonIds.contains(lessonId);
    _setCompleted(lessonId, completed);
    _error = null;
    notifyListeners();

    try {
      await repo.markLessonCompleted(lessonId, completed: completed);
      return true;
    } catch (e) {
      _setCompleted(lessonId, !completed);
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _rememberCompletion(Lesson lesson) =>
      _setCompleted(lesson.id, lesson.isCompleted);

  void _setCompleted(String lessonId, bool completed) {
    if (completed) {
      _completedLessonIds.add(lessonId);
    } else {
      _completedLessonIds.remove(lessonId);
    }
  }
}
