import '../../core/constants.dart';
import '../../models/course.dart';
import '../../models/course_category.dart';
import '../repositories/course_repository.dart';
import 'mock_data.dart';

/// Mock implementation of [CourseRepository] — filters the seed list in
/// [MockData] (AGENT.md §4.3, §6).
class MockCourseRepository implements CourseRepository {
  /// 2.3 Browse by Category — all seed categories.
  @override
  Future<List<CourseCategory>> getCategories() async {
    await Future<void>.delayed(AppConstants.mockLatency);
    return MockData.categories;
  }

  /// 2.1 View Available Courses — only published courses are listed.
  @override
  Future<List<Course>> getPublishedCourses() async {
    await Future<void>.delayed(AppConstants.mockLatency);
    return MockData.courses.where((c) => c.isPublished).toList();
  }

  /// 2.2 Search Courses — case-insensitive match on title, keywords, and
  /// description; published courses only.
  @override
  Future<List<Course>> searchCourses(String query) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return getPublishedCourses();
    return MockData.courses.where((c) {
      if (!c.isPublished) return false;
      final haystack = [
        c.title,
        c.description,
        ...c.keywords,
        ...c.objectives,
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  /// 2.3 Browse by Category — published courses in one category.
  @override
  Future<List<Course>> getCoursesByCategory(String categoryId) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    return MockData.courses
        .where((c) => c.isPublished && c.categoryId == categoryId)
        .toList();
  }

  /// 2.4 View Course Details — full record for one course (published or not,
  /// so the detail page can show a proper status for drafts too).
  @override
  Future<Course> getCourseDetails(String courseId) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    final match = MockData.courses.where((c) => c.id == courseId).firstOrNull;
    if (match == null) {
      throw CourseNotFoundException(courseId);
    }
    return match;
  }
}
