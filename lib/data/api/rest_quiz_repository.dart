import '../../models/quiz.dart';
import '../repositories/quiz_repository.dart';
import 'api_client.dart';

class RestQuizRepository implements QuizRepository {
  final ApiClient _api = ApiClient.instance;

  String _path(String courseId, String lessonId) =>
      '/courses/$courseId/lessons/$lessonId/quiz';

  @override
  Future<QuizSession> load(String courseId, String lessonId) async {
    final res = await _api.get(_path(courseId, lessonId));
    if (!res.isSuccess) _api.fail(res, 'Could not load this quiz.');
    final data = Map<String, dynamic>.from(res.data as Map);
    return QuizSession(
      quiz: LessonQuiz.fromJson(Map<String, dynamic>.from(data['quiz'] as Map)),
      latestAttempt: data['latest_attempt'] == null
          ? null
          : QuizAttempt.fromJson(
              Map<String, dynamic>.from(data['latest_attempt'] as Map),
            ),
    );
  }

  @override
  Future<QuizAttempt> submit(
    String courseId,
    String lessonId,
    int revision,
    List<int> answers,
  ) async {
    final res = await _api.post(
      '${_path(courseId, lessonId)}/attempts',
      body: {'revision': revision, 'answers': answers},
    );
    if (!res.isSuccess) _api.fail(res, 'Could not submit your quiz.');
    return QuizAttempt.fromJson(
      Map<String, dynamic>.from(res.data['attempt'] as Map),
    );
  }
}
