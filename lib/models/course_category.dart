/// Course category model for Module 2 (Browse by Category, 2.3).
/// Pure Dart: no Flutter imports (AGENT.md §7).
class CourseCategory {
  const CourseCategory({
    required this.id,
    required this.name,
    this.description,
    this.courseCount,
  });

  factory CourseCategory.fromJson(Map<String, dynamic> json) =>
      CourseCategory(
        // The API sends numeric ids; mock data uses strings.
        id: json['id'].toString(),
        name: json['name'] as String,
        description: (json['description'] as String?)?.trim().isEmpty ?? true
            ? null
            : (json['description'] as String).trim(),
        // For students the API counts only published courses.
        courseCount: (json['courses_count'] ?? json['courseCount']) as int?,
      );

  final String id;
  final String name;

  /// Set by administrators on the web portal; shown when browsing the category.
  final String? description;

  /// Published courses in this category (null when unknown, e.g. mock data).
  final int? courseCount;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'description': description,
        'courses_count': courseCount,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CourseCategory && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
