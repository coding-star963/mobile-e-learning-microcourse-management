import '../../models/learning_activity.dart';
import '../repositories/progress_repository.dart';
import 'api_client.dart';

/// Module 5 against the Laravel REST API.
class RestProgressRepository implements ProgressRepository {
  final ApiClient _api = ApiClient.instance;

  /// 5.4 View Learning History
  @override
  Future<List<LearningActivity>> getLearningHistory(String studentId) async {
    final res = await _api.get('/progress/history/$studentId', query: {'per_page': 100});
    if (!res.isSuccess) _api.fail(res, 'Could not load your learning history.');
    return ApiClient.dataList(res.data).map(LearningActivity.fromJson).toList();
  }
}
