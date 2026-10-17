import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_e_learning_micro_course_system/models/enrollment.dart';

/// The server can return any of the four enrollment statuses; teachers set
/// suspended/cancelled on the web portal.
void main() {
  Enrollment parse(String status) => Enrollment.fromJson({
        'id': 1,
        'user_id': 2,
        'course_id': 3,
        'status': status,
        'enrolled_at': '2026-10-01T00:00:00Z',
        'completed_lesson_ids': [4],
      });

  test('parses every server status', () {
    expect(parse('active').status, EnrollmentStatus.active);
    expect(parse('completed').status, EnrollmentStatus.completed);
    expect(parse('suspended').status, EnrollmentStatus.suspended);
    expect(parse('cancelled').status, EnrollmentStatus.cancelled);
    expect(parse('unknown').status, EnrollmentStatus.active);
  });

  test('suspended and cancelled enrollments are not open', () {
    expect(parse('active').status.isOpen, isTrue);
    expect(parse('completed').status.isOpen, isTrue);
    expect(parse('suspended').status.isOpen, isFalse);
    expect(parse('cancelled').status.label, 'Cancelled');
    expect(parse('active').completedLessonIds, ['4']);
  });
}
