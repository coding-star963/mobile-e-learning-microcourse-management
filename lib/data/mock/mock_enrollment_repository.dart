import '../../core/constants.dart';
import '../../models/enrollment.dart';
import '../repositories/enrollment_repository.dart';
import 'mock_data.dart';

/// Mock implementation of [EnrollmentRepository] — mutates the in-memory
/// seed list in [MockData] (resets on restart, AGENT.md §6).
class MockEnrollmentRepository implements EnrollmentRepository {
  /// 3.1 Enroll in Course — guards: course must exist, be published, and not
  /// already enrolled.
  @override
  Future<Enrollment> enroll({
    required String studentId,
    required String courseId,
  }) async {
    await Future<void>.delayed(AppConstants.mockLatency);

    final course =
        MockData.courses.where((c) => c.id == courseId).firstOrNull;
    if (course == null) {
      throw const EnrollmentException('This course does not exist.');
    }
    if (!course.isPublished) {
      throw const EnrollmentException(
        'This course is not open for enrollment yet.',
      );
    }
    final existing = MockData.enrollmentJson.any(
      (e) => e['studentId'] == studentId && e['courseId'] == courseId,
    );
    if (existing) {
      throw const EnrollmentException(
        'You are already enrolled in this course.',
      );
    }

    final enrollment = {
      'id': 'enrollment-${DateTime.now().microsecondsSinceEpoch}',
      'studentId': studentId,
      'courseId': courseId,
      'enrolledAt': DateTime.now().toUtc().toIso8601String(),
      'completedLessonIds': <String>[],
      'status': 'active',
    };
    MockData.enrollmentJson.add(enrollment);
    return Enrollment.fromJson(enrollment);
  }

  /// 3.2 View Enrolled Courses — all enrollments of the student.
  @override
  Future<List<Enrollment>> getMyEnrollments(String studentId) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    return MockData.enrollmentsFor(studentId);
  }

  /// 3.3 View Enrollment Details — one enrollment, ownership-checked.
  @override
  Future<Enrollment> getEnrollmentDetails({
    required String studentId,
    required String enrollmentId,
  }) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    final match = MockData.enrollmentJson
        .map(Enrollment.fromJson)
        .where((e) => e.id == enrollmentId && e.studentId == studentId)
        .firstOrNull;
    if (match == null) {
      throw const EnrollmentException('Enrollment not found.');
    }
    return match;
  }

  /// 3.4 Access Enrolled Course — enrollment by course, null if none.
  @override
  Future<Enrollment?> getEnrollmentForCourse({
    required String studentId,
    required String courseId,
  }) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    final match = MockData.enrollmentJson
        .map(Enrollment.fromJson)
        .where((e) => e.studentId == studentId && e.courseId == courseId)
        .firstOrNull;
    return match;
  }
}
