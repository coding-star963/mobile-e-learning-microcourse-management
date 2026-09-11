/// Course category model for Module 2 (Browse by Category, 2.3).
/// Pure Dart: no Flutter imports (AGENT.md §7).
class CourseCategory {
  const CourseCategory({
    required this.id,
    required this.name,
  });

  factory CourseCategory.fromJson(Map<String, dynamic> json) =>
      CourseCategory(
        id: json['id'] as String,
        name: json['name'] as String,
      );

  final String id;
  final String name;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CourseCategory && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
