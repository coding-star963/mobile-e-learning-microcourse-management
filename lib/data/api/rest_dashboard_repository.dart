import '../../models/student_dashboard.dart';
import '../repositories/dashboard_repository.dart';
import 'api_client.dart';

/// Module 7 against the Laravel REST API (`GET /dashboard` for a student).
class RestDashboardRepository implements DashboardRepository {
  final ApiClient _api = ApiClient.instance;

  @override
  Future<StudentDashboard> getDashboard(String studentId) async {
    final res = await _api.get('/dashboard');
    if (!res.isSuccess || res.data is! Map) _api.fail(res, 'Could not load your dashboard.');
    return StudentDashboard.fromJson(Map<String, dynamic>.from(res.data as Map));
  }
}
