import '../../models/enrollment.dart';
import '../mock/mock_enrollment_repository.dart';
import '../repositories/enrollment_repository.dart';
import 'api_client.dart';

class RestEnrollmentRepository implements EnrollmentRepository {
  final ApiClient _api = ApiClient.instance;
  final MockEnrollmentRepository _mock = MockEnrollmentRepository();

  @override
  Future<Enrollment> enroll({
    required String studentId,
    required String courseId,
  }) async {
    final res = await _api.post('/enrollments', body: {
      'user_id': studentId,
      'course_id': courseId,
    });

    if (res.isSuccess && res.data != null) {
      final item = res.data is Map && res.data.containsKey('data')
          ? res.data['data']
          : (res.data is Map && res.data.containsKey('enrollment')
              ? res.data['enrollment']
              : res.data);
      if (item is Map) {
        return Enrollment.fromJson(Map<String, dynamic>.from(item));
      }
    }

    if (res.statusCode == 422) {
      throw EnrollmentException(
        res.message ?? 'This student is already enrolled in this course.',
      );
    }

    if (res.statusCode == 0) {
      return _mock.enroll(studentId: studentId, courseId: courseId);
    }

    throw EnrollmentException(res.message ?? 'Enrollment failed.');
  }

  @override
  Future<List<Enrollment>> getMyEnrollments(String studentId) async {
    final res = await _api.get('/enrollments/student/$studentId');
    if (res.isSuccess && res.data != null) {
      final list = res.data is Map && res.data.containsKey('data')
          ? res.data['data']
          : res.data;
      if (list is List) {
        return list
            .whereType<Map>()
            .map((e) => Enrollment.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    return _mock.getMyEnrollments(studentId);
  }

  @override
  Future<Enrollment> getEnrollmentDetails({
    required String studentId,
    required String enrollmentId,
  }) async {
    final res = await _api.get('/enrollments/$enrollmentId');
    if (res.isSuccess && res.data != null) {
      final item = res.data is Map && res.data.containsKey('data')
          ? res.data['data']
          : res.data;
      if (item is Map) {
        return Enrollment.fromJson(Map<String, dynamic>.from(item));
      }
    }
    return _mock.getEnrollmentDetails(
      studentId: studentId,
      enrollmentId: enrollmentId,
    );
  }

  @override
  Future<Enrollment?> getEnrollmentForCourse({
    required String studentId,
    required String courseId,
  }) async {
    final res = await _api.get('/enrollments/student/$studentId');
    if (res.isSuccess && res.data != null) {
      final list = res.data is Map && res.data.containsKey('data')
          ? res.data['data']
          : res.data;
      if (list is List) {
        for (final item in list.whereType<Map>()) {
          final enr = Enrollment.fromJson(Map<String, dynamic>.from(item));
          if (enr.courseId == courseId) {
            return enr;
          }
        }
        return null;
      }
    }
    return _mock.getEnrollmentForCourse(
      studentId: studentId,
      courseId: courseId,
    );
  }
}
