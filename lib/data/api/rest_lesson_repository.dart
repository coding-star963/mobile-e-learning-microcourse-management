import '../../models/lesson.dart';
import '../repositories/lesson_repository.dart';
import 'api_client.dart';

/// Modules 4 and 5.1 against the Laravel REST API. The server only returns
/// published lessons to students, each flagged with `is_completed`.
class RestLessonRepository implements LessonRepository {
  final ApiClient _api = ApiClient.instance;

  /// 4.1 View Course Lessons / 4.5 Follow Lesson Order
  @override
  Future<List<Lesson>> getLessonsForCourse(String courseId) async {
    final res = await _api.get('/courses/$courseId/lessons');
    if (!res.isSuccess) _api.fail(res, 'Could not load lessons.');
    final lessons = ApiClient.dataList(res.data).map(Lesson.fromJson).toList();
    lessons.sort((a, b) => a.order.compareTo(b.order));
    return lessons;
  }

  /// 4.2 View Lesson Details
  @override
  Future<Lesson?> getLessonDetails(String courseId, String lessonId) async {
    final res = await _api.get('/courses/$courseId/lessons/$lessonId');
    if (res.statusCode == 404) return null;
    final item = res.isSuccess ? ApiClient.dataItem(res.data, 'lesson') : null;
    if (item == null) _api.fail(res, 'Could not load the lesson.');
    return Lesson.fromJson(item);
  }

  /// 5.1 Track Lesson Completion — saved on the server for the student's enrollment.
  @override
  Future<bool> markLessonCompleted(String lessonId, {bool completed = true}) async {
    final res = await _api.put('/lessons/$lessonId/progress', body: {'completed': completed});
    if (!res.isSuccess) _api.fail(res, 'Could not save your progress.');
    return true;
  }
}
