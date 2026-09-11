import '../../models/enrollment.dart';

/// Contract for Module 3 — Course Enrollment (AGENT.md §4.3). Methods align
/// with the future REST endpoints in AGENT.md §5.
abstract class EnrollmentRepository {
  /// 3.1 Enroll in Course — creates an enrollment for the current student.
  /// Throws [EnrollmentException] if the course is unpublished, unknown, or
  /// already enrolled.
  Future<Enrollment> enroll({
    required String studentId,
    required String courseId,
  });

  /// 3.2 View Enrolled Courses — all enrollments of the current student.
  Future<List<Enrollment>> getMyEnrollments(String studentId);

  /// 3.3 View Enrollment Details — one enrollment by id.
  /// Throws [EnrollmentException] if not found or not owned by the student.
  Future<Enrollment> getEnrollmentDetails({
    required String studentId,
    required String enrollmentId,
  });

  /// 3.4 Access Enrolled Course — look up an enrollment by course for the
  /// current student (null = not enrolled).
  Future<Enrollment?> getEnrollmentForCourse({
    required String studentId,
    required String courseId,
  });
}

/// Domain error for enrollment failures (AGENT.md §7).
class EnrollmentException implements Exception {
  const EnrollmentException(this.message);

  final String message;

  @override
  String toString() => message;
}
