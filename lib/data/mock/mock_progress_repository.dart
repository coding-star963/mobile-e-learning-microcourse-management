import '../../core/constants.dart';
import '../../models/learning_activity.dart';
import '../repositories/progress_repository.dart';
import 'mock_data.dart';

/// Mock implementation of [ProgressRepository] (Module 5).
class MockProgressRepository implements ProgressRepository {
  @override
  Future<List<LearningActivity>> getLearningHistory(String studentId) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    final courses = MockData.courses;
    final history = <LearningActivity>[];

    for (final enrollment in MockData.enrollmentsFor(studentId)) {
      final course = courses.firstWhere((c) => c.id == enrollment.courseId);
      for (final lessonId in enrollment.completedLessonIds) {
        final lesson = MockData.lessonById(lessonId);
        if (lesson == null) continue;
        history.add(LearningActivity(
          lessonId: lesson.id,
          lessonTitle: lesson.title,
          courseId: course.id,
          courseTitle: course.title,
          completedAt: enrollment.enrolledAt.add(const Duration(days: 1)),
        ));
      }
    }

    history.sort((a, b) => (b.completedAt ?? DateTime(0)).compareTo(a.completedAt ?? DateTime(0)));
    return history;
  }
}
