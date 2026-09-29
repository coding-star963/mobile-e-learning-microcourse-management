import '../../models/lesson.dart';
import '../mock/mock_lesson_repository.dart';
import '../repositories/lesson_repository.dart';
import 'api_client.dart';

class RestLessonRepository implements LessonRepository {
  final ApiClient _api = ApiClient.instance;
  final MockLessonRepository _mock = MockLessonRepository();

  @override
  Future<List<Lesson>> getLessonsForCourse(String courseId) async {
    final res = await _api.get('/courses/$courseId/lessons');
    if (res.isSuccess && res.data != null) {
      final list = res.data is Map && res.data.containsKey('data')
          ? res.data['data']
          : res.data;
      if (list is List && list.isNotEmpty) {
        final lessons = list
            .whereType<Map>()
            .map((m) => Lesson.fromJson(Map<String, dynamic>.from(m)))
            .toList();
        lessons.sort((a, b) => a.order.compareTo(b.order));
        return lessons;
      }
    }
    return _mock.getLessonsForCourse(courseId);
  }

  @override
  Future<Lesson?> getLessonDetails(String courseId, String lessonId) async {
    final res = await _api.get('/courses/$courseId/lessons/$lessonId');
    if (res.isSuccess && res.data != null) {
      final item = res.data is Map && res.data.containsKey('data')
          ? res.data['data']
          : (res.data is Map && res.data.containsKey('lesson')
              ? res.data['lesson']
              : res.data);
      if (item is Map) {
        return Lesson.fromJson(Map<String, dynamic>.from(item));
      }
    }
    return _mock.getLessonDetails(courseId, lessonId);
  }

  @override
  Future<bool> markLessonCompleted(String lessonId) async {
    final res = await _api.put('/lessons/$lessonId/progress');
    if (res.isSuccess) {
      return true;
    }
    return _mock.markLessonCompleted(lessonId);
  }
}
