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
  final Set<String> _completedLessonIds = {'lesson-001', 'lesson-007'};

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Set<String> get completedLessonIds => _completedLessonIds;

  List<Lesson> lessonsFor(String courseId) =>
      _courseLessons[courseId] ?? const [];

  Lesson? cachedLesson(String lessonId) => _lessonDetails[lessonId];

  bool isCompleted(String lessonId) => _completedLessonIds.contains(lessonId);

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
        notifyListeners();
      }
      return lesson;
    } catch (e) {
      _error = 'Failed to load lesson details: $e';
      notifyListeners();
      return cached;
    }
  }

  /// 5.1 Track Lesson Completion
  Future<bool> toggleLessonCompleted(String lessonId) async {
    final currentlyDone = _completedLessonIds.contains(lessonId);
    if (currentlyDone) {
      _completedLessonIds.remove(lessonId);
    } else {
      _completedLessonIds.add(lessonId);
    }
    notifyListeners();

    try {
      await repo.markLessonCompleted(lessonId);
      return true;
    } catch (_) {
      return true; // Optimistic update
    }
  }
}
