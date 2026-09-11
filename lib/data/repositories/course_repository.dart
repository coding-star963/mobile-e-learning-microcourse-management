import '../../models/course.dart';
import '../../models/course_category.dart';

/// Contract for Module 2 — Course Discovery & Browsing (AGENT.md §4.3).
/// Methods align with the future REST endpoints in AGENT.md §5.
abstract class CourseRepository {
  /// 2.3 Browse by Category — all categories available in the catalog.
  Future<List<CourseCategory>> getCategories();

  /// 2.1 View Available Courses — published micro-courses open for enrollment.
  Future<List<Course>> getPublishedCourses();

  /// 2.2 Search Courses — matches course titles, keywords, or descriptions.
  Future<List<Course>> searchCourses(String query);

  /// 2.3 Browse by Category — published courses in one category.
  Future<List<Course>> getCoursesByCategory(String categoryId);

  /// 2.4 View Course Details — full detail record for one course.
  /// Throws [CourseNotFoundException] when the id is unknown.
  Future<Course> getCourseDetails(String courseId);
}

/// Domain error for unknown course ids (AGENT.md §7).
class CourseNotFoundException implements Exception {
  const CourseNotFoundException(this.courseId);

  final String courseId;

  @override
  String toString() => 'Course not found: $courseId';
}
