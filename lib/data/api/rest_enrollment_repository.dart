import '../../models/enrollment.dart';
import '../repositories/enrollment_repository.dart';
import 'api_client.dart';

/// Module 3 against the Laravel REST API. Errors are surfaced as
/// [EnrollmentException]s; there is no fallback to mock data.
class RestEnrollmentRepository implements EnrollmentRepository {
  final ApiClient _api = ApiClient.instance;

  /// 3.1 Enroll in Course — the server always enrolls the signed-in student.
  @override
  Future<Enrollment> enroll({
    required String studentId,
    required String courseId,
  }) async {
    final res = await _api.post('/enrollments', body: {'course_id': courseId});
    final item = res.isSuccess ? ApiClient.dataItem(res.data, 'enrollment') : null;
    if (item == null) {
      throw EnrollmentException(_api.errorMessage(res, 'Enrollment failed.'));
    }
    return Enrollment.fromJson(item);
  }

  /// 3.2 View Enrolled Courses
  @override
  Future<List<Enrollment>> getMyEnrollments(String studentId) async {
    final res = await _api.get('/enrollments/student/$studentId', query: {'per_page': 100});
    if (!res.isSuccess) {
      throw EnrollmentException(_api.errorMessage(res, 'Could not load your courses.'));
    }
    return ApiClient.dataList(res.data).map(Enrollment.fromJson).toList();
  }

  /// 3.3 View Enrollment Details
  @override
  Future<Enrollment> getEnrollmentDetails({
    required String studentId,
    required String enrollmentId,
  }) async {
    final res = await _api.get('/enrollments/$enrollmentId');
    final item = res.isSuccess ? ApiClient.dataItem(res.data) : null;
    if (item == null) {
      throw EnrollmentException(_api.errorMessage(res, 'Enrollment not found.'));
    }
    return Enrollment.fromJson(item);
  }

  /// 3.4 Access Enrolled Course
  @override
  Future<Enrollment?> getEnrollmentForCourse({
    required String studentId,
    required String courseId,
  }) async {
    final enrollments = await getMyEnrollments(studentId);
    for (final enrollment in enrollments) {
      if (enrollment.courseId == courseId) return enrollment;
    }
    return null;
  }
}
