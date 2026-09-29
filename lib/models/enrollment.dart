/// Enrollment model for Module 3 (Course Enrollment, 3.1–3.4) and Module 5
/// (Learning Progress). Pure Dart: no Flutter imports (AGENT.md §7).
class Enrollment {
  const Enrollment({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.enrolledAt,
    required this.completedLessonIds,
    this.status = EnrollmentStatus.active,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    DateTime parsedEnrolledAt;
    final rawDate = json['enrolledAt'] ?? json['enrolled_at'] ?? json['created_at'];
    if (rawDate is String) {
      parsedEnrolledAt = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedEnrolledAt = DateTime.now();
    }

    EnrollmentStatus parsedStatus = EnrollmentStatus.active;
    final rawStatus = json['status']?.toString().toLowerCase();
    if (rawStatus == 'completed') {
      parsedStatus = EnrollmentStatus.completed;
    }

    return Enrollment(
      id: json['id']?.toString() ?? '',
      studentId: (json['studentId'] ??
              json['user_id'] ??
              (json['user'] is Map ? json['user']['id'] : null))
          ?.toString() ??
          '',
      courseId: (json['courseId'] ??
              json['course_id'] ??
              (json['course'] is Map ? json['course']['id'] : null))
          ?.toString() ??
          '',
      enrolledAt: parsedEnrolledAt,
      completedLessonIds: List<String>.from(
        (json['completedLessonIds'] ?? json['completed_lesson_ids'] as List?)
                ?.map((e) => e.toString()) ??
            const [],
      ),
      status: parsedStatus,
    );
  }

  final String id;
  final String studentId;
  final String courseId;
  final DateTime enrolledAt;

  /// Lesson ids the student has completed (drives 5.1–5.3 and 3.4 "continue").
  final List<String> completedLessonIds;

  final EnrollmentStatus status;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'studentId': studentId,
        'courseId': courseId,
        'enrolledAt': enrolledAt.toIso8601String(),
        'completedLessonIds': completedLessonIds,
        'status': status.name,
      };

  Enrollment copyWith({
    String? id,
    String? studentId,
    String? courseId,
    DateTime? enrolledAt,
    List<String>? completedLessonIds,
    EnrollmentStatus? status,
  }) =>
      Enrollment(
        id: id ?? this.id,
        studentId: studentId ?? this.studentId,
        courseId: courseId ?? this.courseId,
        enrolledAt: enrolledAt ?? this.enrolledAt,
        completedLessonIds: completedLessonIds ?? this.completedLessonIds,
        status: status ?? this.status,
      );

  /// 5.3 completion percentage — needs the course's total lesson count.
  /// Returns 0.0–1.0.
  double progressFraction(int totalLessons) {
    if (totalLessons <= 0) return 0.0;
    return (completedLessonIds.length / totalLessons).clamp(0.0, 1.0);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Enrollment && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Enrollment status shown in 3.2/3.3 and driven by Module 5 completion.
enum EnrollmentStatus { active, completed }
