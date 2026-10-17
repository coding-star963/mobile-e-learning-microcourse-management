/// Announcement / notification model for Module 6 (6.1–6.4) and the
/// dashboard's recent announcements (7.4). Pure Dart (AGENT.md §7).
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    this.type = 'general',
    this.courseId,
    this.courseTitle,
    this.authorName,
    this.publishedAt,
  });

  /// Accepts the API resource (`course`/`user` objects) and the dashboard's
  /// flattened shape (`course`/`author` strings).
  factory Announcement.fromJson(Map<String, dynamic> json) {
    final course = json['course'];
    final user = json['user'];
    return Announcement(
      id: json['id']?.toString() ?? '',
      title: (json['title'] ?? '') as String,
      content: (json['content'] ?? '') as String,
      type: (json['type'] ?? 'general') as String,
      courseId: (json['courseId'] ?? json['course_id'] ?? (course is Map ? course['id'] : null))?.toString(),
      courseTitle: (json['courseTitle'] ?? (course is Map ? course['title'] : course))?.toString(),
      authorName: (json['authorName'] ?? json['author'] ?? (user is Map ? user['name'] : null))?.toString(),
      publishedAt: DateTime.tryParse(
              (json['publishedAt'] ?? json['published_at'])?.toString() ?? '')
          ?.toLocal(),
    );
  }

  final String id;
  final String title;
  final String content;

  /// 'general', 'course_update' (6.2), 'important', or 'enrollment' (a
  /// personal notice from GET /notifications).
  final String type;
  final String? courseId;
  final String? courseTitle;
  final String? authorName;
  final DateTime? publishedAt;

  bool get isCourseUpdate => type == 'course_update';
  bool get isImportant => type == 'important';

  /// A personal notice about the student's own enrollment or account.
  bool get isEnrollmentNotice => type == 'enrollment';

  String get typeLabel => switch (type) {
        'course_update' => 'Course update',
        'important' => 'Important',
        'enrollment' => 'My enrollment',
        _ => 'General',
      };

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'content': content,
        'type': type,
        'course_id': courseId,
        'courseTitle': courseTitle,
        'authorName': authorName,
        'published_at': publishedAt?.toUtc().toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Announcement && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
