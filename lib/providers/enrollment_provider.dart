import 'package:flutter/foundation.dart';

import '../data/repositories/enrollment_repository.dart';
import '../models/enrollment.dart';

/// State holder for Module 3 — Course Enrollment (3.1–3.4).
/// Screens watch [enrollments]/[isLoading]/[error] and call actions via
/// context.read (AGENT.md §4.4, §7).
class EnrollmentProvider extends ChangeNotifier {
  EnrollmentProvider({required EnrollmentRepository repo})
      : _enrollmentRepository = repo;

  final EnrollmentRepository _enrollmentRepository;

  List<Enrollment> enrollments = [];
  bool isLoading = false;
  String? error;

  /// 3.4 lookups cached per course id for the detail screen's action button.
  final Map<String, Enrollment?> _enrollmentByCourse = {};

  /// 3.2 View Enrolled Courses — loads all enrollments for the student.
  /// [silent] refreshes in the background: no spinner, and the current list
  /// stays on screen if the request fails.
  Future<void> loadEnrollments(String studentId, {bool silent = false}) async {
    if (silent) {
      try {
        enrollments = await _enrollmentRepository.getMyEnrollments(studentId);
        // Course screens re-check their enrollment against the fresh data.
        _enrollmentByCourse.clear();
        error = null;
        notifyListeners();
      } on Exception catch (_) {}
      return;
    }
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      enrollments = await _enrollmentRepository.getMyEnrollments(studentId);
    } on Exception catch (e) {
      error = 'Could not load your courses. Please try again.';
      debugPrint('EnrollmentProvider.loadEnrollments failed: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// 3.1 Enroll in Course — returns true on success; error message otherwise.
  Future<bool> enroll({
    required String studentId,
    required String courseId,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final enrollment = await _enrollmentRepository.enroll(
        studentId: studentId,
        courseId: courseId,
      );
      enrollments = [...enrollments, enrollment];
      _enrollmentByCourse[courseId] = enrollment;
      return true;
    } on Exception catch (e) {
      error = e is EnrollmentException
          ? e.message
          : 'Could not enroll. Please try again.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// 3.3 View Enrollment Details — fetches one enrollment by id.
  Future<Enrollment> loadEnrollmentDetails({
    required String studentId,
    required String enrollmentId,
  }) async {
    return _enrollmentRepository.getEnrollmentDetails(
      studentId: studentId,
      enrollmentId: enrollmentId,
    );
  }

  /// 3.4 Access Enrolled Course — cached lookup by course id.
  Future<Enrollment?> getEnrollmentForCourse({
    required String studentId,
    required String courseId,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _enrollmentByCourse.containsKey(courseId)) {
      return _enrollmentByCourse[courseId];
    }
    final enrollment = await _enrollmentRepository.getEnrollmentForCourse(
      studentId: studentId,
      courseId: courseId,
    );
    _enrollmentByCourse[courseId] = enrollment;
    return enrollment;
  }

  /// Clears the per-course cache so detail screens refetch after enrollment
  /// state changes elsewhere (used by Module 5 progress updates later).
  void invalidateCourseLookup(String courseId) =>
      _enrollmentByCourse.remove(courseId);
}
