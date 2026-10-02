/// One completed lesson in the student's learning history (5.4) and the
/// dashboard's recent activity (7.1). Pure Dart (AGENT.md §7).
class LearningActivity {
  const LearningActivity({
    required this.lessonId,
    required this.lessonTitle,
    required this.courseId,
    required this.courseTitle,
    this.completedAt,
  });

  /// Accepts the API's lesson-progress resource (nested `lesson.course`) and
  /// the dashboard's flattened shape.
  factory LearningActivity.fromJson(Map<String, dynamic> json) {
    final lesson = json['lesson'] is Map ? json['lesson'] as Map : const {};
    final course = lesson['course'] is Map ? lesson['course'] as Map : const {};
    return LearningActivity(
      lessonId: (json['lessonId'] ?? json['lesson_id'] ?? lesson['id'])?.toString() ?? '',
      lessonTitle: (json['lessonTitle'] ?? json['lesson_title'] ?? lesson['title'] ?? '').toString(),
      courseId: (json['courseId'] ?? json['course_id'] ?? course['id'])?.toString() ?? '',
      courseTitle: (json['courseTitle'] ?? json['course_title'] ?? course['title'] ?? '').toString(),
      completedAt: DateTime.tryParse(
              (json['completedAt'] ?? json['completed_at'])?.toString() ?? '')
          ?.toLocal(),
    );
  }

  final String lessonId;
  final String lessonTitle;
  final String courseId;
  final String courseTitle;
  final DateTime? completedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'lesson_id': lessonId,
        'lesson_title': lessonTitle,
        'course_id': courseId,
        'course_title': courseTitle,
        'completed_at': completedAt?.toUtc().toIso8601String(),
      };
}
