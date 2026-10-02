import '../../models/course.dart';
import '../../models/course_category.dart';
import '../repositories/course_repository.dart';
import 'api_client.dart';

/// Module 2 against the Laravel REST API. Only published courses are
/// requested (the server also enforces this for students).
class RestCourseRepository implements CourseRepository {
  final ApiClient _api = ApiClient.instance;

  static const Map<String, dynamic> _published = {
    'status': 'published',
    'per_page': 100,
  };

  @override
  Future<List<CourseCategory>> getCategories() async {
    final res = await _api.get('/categories', query: {'per_page': 100});
    if (!res.isSuccess) _api.fail(res, 'Could not load categories.');
    return ApiClient.dataList(res.data).map(CourseCategory.fromJson).toList();
  }

  /// 2.1 View Available Courses
  @override
  Future<List<Course>> getPublishedCourses() => _courses(_published);

  /// 2.2 Search Courses
  @override
  Future<List<Course>> searchCourses(String query) =>
      _courses({..._published, 'search': query.trim()});

  /// 2.3 Browse by Category
  @override
  Future<List<Course>> getCoursesByCategory(String categoryId) =>
      _courses({..._published, 'category_id': categoryId});

  /// 2.4 View Course Details — the server accepts the numeric id or the slug.
  @override
  Future<Course> getCourseDetails(String courseId) async {
    final res = await _api.get('/courses/$courseId');
    if (res.statusCode == 403 || res.statusCode == 404) {
      throw CourseNotFoundException(courseId);
    }
    final item = res.isSuccess ? ApiClient.dataItem(res.data, 'course') : null;
    if (item == null) _api.fail(res, 'Could not load the course.');
    return Course.fromJson(item);
  }

  Future<List<Course>> _courses(Map<String, dynamic> query) async {
    final res = await _api.get('/courses', query: query);
    if (!res.isSuccess) _api.fail(res, 'Could not load courses.');
    return ApiClient.dataList(res.data).map(Course.fromJson).toList();
  }
}
