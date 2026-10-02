import '../../core/constants.dart';
import '../../models/student_dashboard.dart';
import '../repositories/dashboard_repository.dart';
import 'mock_data.dart';

/// Mock implementation of [DashboardRepository] (Module 7). Builds the same
/// JSON shape as `GET /dashboard` from the in-memory seeds.
class MockDashboardRepository implements DashboardRepository {
  @override
  Future<StudentDashboard> getDashboard(String studentId) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    final courses = MockData.courses;
    final categoryNames = {for (final c in MockData.categories) c.id: c.name};

    final courseJson = MockData.enrollmentsFor(studentId).map((enrollment) {
      final course = courses.firstWhere((c) => c.id == enrollment.courseId);
      final lessons = MockData.lessonsForCourse(course.id).where((l) => l.status == 'published').toList();
      final done = lessons.where((l) => enrollment.completedLessonIds.contains(l.id)).length;
      final next = lessons.where((l) => !enrollment.completedLessonIds.contains(l.id) && !l.isLocked);
      return <String, dynamic>{
        'status': enrollment.status.name,
        'course': {'id': course.id, 'title': course.title, 'category': categoryNames[course.categoryId] ?? ''},
        'total_lessons': lessons.length,
        'completed_lessons': done,
        'progress': lessons.isEmpty ? 0 : done / lessons.length * 100,
        'next_lesson': next.isEmpty ? null : {'id': next.first.id, 'title': next.first.title},
      };
    }).toList();

    final active = courseJson.where((c) => c['status'] == 'active').toList();
    final average = courseJson.isEmpty
        ? 0
        : courseJson.map((c) => c['progress'] as num).reduce((a, b) => a + b) / courseJson.length;

    return StudentDashboard.fromJson({
      'summary': {
        'enrolled_courses': courseJson.length,
        'in_progress_courses': active.length,
        'completed_courses': courseJson.length - active.length,
        'completed_lessons': courseJson.fold<int>(0, (sum, c) => sum + (c['completed_lessons'] as int)),
        'average_progress': average,
      },
      'continue_learning': active.isEmpty ? null : active.first,
      'courses': courseJson,
      'recent_activity': const [],
      'recent_announcements': MockData.announcementJson,
    });
  }
}
