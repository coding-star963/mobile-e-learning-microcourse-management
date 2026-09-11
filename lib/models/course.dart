/// Course model for Module 2 (Course Discovery & Browsing, 2.1–2.5) and
/// Module 3 (Enrollment, 3.x). Pure Dart: no Flutter imports (AGENT.md §7).
class Course {
  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.objectives,
    required this.difficultyLevel,
    required this.isPublished,
    required this.lessonIds,
    this.thumbnailUrl,
    this.keywords = const [],
  });

  factory Course.fromJson(Map<String, dynamic> json) => Course(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        categoryId: json['categoryId'] as String,
        objectives: List<String>.from(json['objectives'] as List),
        difficultyLevel: json['difficultyLevel'] as String,
        isPublished: json['isPublished'] as bool,
        lessonIds: List<String>.from(json['lessonIds'] as List),
        thumbnailUrl: json['thumbnailUrl'] as String?,
        keywords:
            json['keywords'] == null ? const [] : List<String>.from(json['keywords'] as List),
      );

  final String id;
  final String title;
  final String description;
  final String categoryId;

  /// Learning objectives shown on the course detail page (2.4).
  final List<String> objectives;

  /// e.g. 'beginner', 'intermediate', 'advanced'.
  final String difficultyLevel;

  /// Only published courses are browsable/enrollable (2.1, 2.5).
  final bool isPublished;

  /// Ordered lesson ids as arranged by the teacher (used by Module 4).
  final List<String> lessonIds;

  final String? thumbnailUrl;

  /// Extra searchable keywords for 2.2 Search Courses.
  final List<String> keywords;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'description': description,
        'categoryId': categoryId,
        'objectives': objectives,
        'difficultyLevel': difficultyLevel,
        'isPublished': isPublished,
        'lessonIds': lessonIds,
        'thumbnailUrl': thumbnailUrl,
        'keywords': keywords,
      };

  /// 2.5 View Course Status — students can only enroll in published courses.
  bool get isAvailableForEnrollment => isPublished;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Course && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
