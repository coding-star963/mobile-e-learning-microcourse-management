import '../../models/course.dart';
import '../../models/course_category.dart';
import '../mock/mock_course_repository.dart';
import '../repositories/course_repository.dart';
import 'api_client.dart';

class RestCourseRepository implements CourseRepository {
  final ApiClient _api = ApiClient.instance;
  final MockCourseRepository _mock = MockCourseRepository();

  @override
  Future<List<CourseCategory>> getCategories() async {
    final res = await _api.get('/categories');
    if (res.isSuccess && res.data != null) {
      final list = res.data is Map && res.data.containsKey('data')
          ? res.data['data']
          : res.data;
      if (list is List && list.isNotEmpty) {
        return list
            .whereType<Map>()
            .map((e) => CourseCategory.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    return _mock.getCategories();
  }

  @override
  Future<List<Course>> getPublishedCourses() async {
    final res = await _api.get('/courses', query: {'status': 'published'});
    if (res.isSuccess && res.data != null) {
      final list = res.data is Map && res.data.containsKey('data')
          ? res.data['data']
          : res.data;
      if (list is List && list.isNotEmpty) {
        return list
            .whereType<Map>()
            .map((e) => Course.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    return _mock.getPublishedCourses();
  }

  @override
  Future<List<Course>> searchCourses(String query) async {
    final res = await _api.get('/courses', query: {'search': query.trim()});
    if (res.isSuccess && res.data != null) {
      final list = res.data is Map && res.data.containsKey('data')
          ? res.data['data']
          : res.data;
      if (list is List) {
        return list
            .whereType<Map>()
            .map((e) => Course.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    return _mock.searchCourses(query);
  }

  @override
  Future<List<Course>> getCoursesByCategory(String categoryId) async {
    final res = await _api.get('/courses', query: {'category_id': categoryId});
    if (res.isSuccess && res.data != null) {
      final list = res.data is Map && res.data.containsKey('data')
          ? res.data['data']
          : res.data;
      if (list is List) {
        return list
            .whereType<Map>()
            .map((e) => Course.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    return _mock.getCoursesByCategory(categoryId);
  }

  @override
  Future<Course> getCourseDetails(String courseId) async {
    final res = await _api.get('/courses/$courseId');
    if (res.isSuccess && res.data != null) {
      final item = res.data is Map && res.data.containsKey('data')
          ? res.data['data']
          : (res.data is Map && res.data.containsKey('course') ? res.data['course'] : res.data);
      if (item is Map) {
        return Course.fromJson(Map<String, dynamic>.from(item));
      }
    }
    return _mock.getCourseDetails(courseId);
  }
}
