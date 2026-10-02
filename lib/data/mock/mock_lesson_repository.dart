import '../../models/lesson.dart';
import '../repositories/lesson_repository.dart';
import 'mock_data.dart';

/// Mock implementation of [LessonRepository] for Module 4 (4.1–4.6)
/// and Module 5 (5.1).
class MockLessonRepository implements LessonRepository {
  final Set<String> _completedLessonIds = {'lesson-001', 'lesson-007'};

  @override
  Future<List<Lesson>> getLessonsForCourse(String courseId) async {
    return MockData.lessonsForCourse(courseId).map(_withCompletion).toList();
  }

  @override
  Future<Lesson?> getLessonDetails(String courseId, String lessonId) async {
    final lesson = MockData.lessonById(lessonId);
    if (lesson != null) return _withCompletion(lesson);
    final courseLessons = MockData.lessonsForCourse(courseId);
    for (final l in courseLessons) {
      if (l.id == lessonId) return _withCompletion(l);
    }
    return null;
  }

  @override
  Future<bool> markLessonCompleted(String lessonId, {bool completed = true}) async {
    if (completed) {
      _completedLessonIds.add(lessonId);
    } else {
      _completedLessonIds.remove(lessonId);
    }
    return true;
  }

  /// Flags the lesson with this student's completion, like the REST API does.
  Lesson _withCompletion(Lesson lesson) => Lesson.fromJson({
        ...lesson.toJson(),
        'is_completed': _completedLessonIds.contains(lesson.id),
      });
}
