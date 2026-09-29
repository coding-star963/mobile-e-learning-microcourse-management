import '../../models/lesson.dart';
import '../repositories/lesson_repository.dart';
import 'mock_data.dart';

/// Mock implementation of [LessonRepository] for Module 4 (4.1–4.6)
/// and Module 5 (5.1).
class MockLessonRepository implements LessonRepository {
  final Set<String> _completedLessonIds = {'lesson-001', 'lesson-007'};

  @override
  Future<List<Lesson>> getLessonsForCourse(String courseId) async {
    return MockData.lessonsForCourse(courseId);
  }

  @override
  Future<Lesson?> getLessonDetails(String courseId, String lessonId) async {
    final lesson = MockData.lessonById(lessonId);
    if (lesson != null) return lesson;
    final courseLessons = MockData.lessonsForCourse(courseId);
    for (final l in courseLessons) {
      if (l.id == lessonId) return l;
    }
    return null;
  }

  @override
  Future<bool> markLessonCompleted(String lessonId) async {
    _completedLessonIds.add(lessonId);
    return true;
  }
}
