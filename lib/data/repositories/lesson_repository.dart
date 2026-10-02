import '../../models/lesson.dart';

/// Repository interface for Module 4 (Lesson & Learning Content, 4.1–4.6)
/// and Module 5 (Learning Progress, 5.1).
abstract class LessonRepository {
  /// 4.1 View Course Lessons — get lessons for an enrolled or browsed course
  Future<List<Lesson>> getLessonsForCourse(String courseId);

  /// 4.2 View Lesson Details — detailed lesson information
  Future<Lesson?> getLessonDetails(String courseId, String lessonId);

  /// 5.1 Track Lesson Completion — marks a lesson as completed, or as not
  /// completed when [completed] is false.
  Future<bool> markLessonCompleted(String lessonId, {bool completed = true});
}
