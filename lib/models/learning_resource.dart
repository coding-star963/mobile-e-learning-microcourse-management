/// Learning resource model for Module 4 (4.4 View/Download Learning Resources).
/// Pure Dart: no Flutter imports (AGENT.md §7).
class LearningResource {
  const LearningResource({
    required this.id,
    required this.name,
    this.fileUrl,
    this.fileType = 'pdf',
    this.fileSize = 0,
    this.order = 1,
  });

  factory LearningResource.fromJson(Map<String, dynamic> json) =>
      LearningResource(
        id: json['id']?.toString() ?? '',
        name: (json['name'] ?? 'Resource') as String,
        fileUrl: (json['fileUrl'] ?? json['file_url']) as String?,
        fileType: (json['fileType'] ?? json['file_type'] ?? 'pdf') as String,
        fileSize: (json['fileSize'] ?? json['file_size'] ?? 0) as int,
        order: (json['order'] ?? 1) as int,
      );

  final String id;
  final String name;
  final String? fileUrl;
  final String fileType;
  final int fileSize;
  final int order;

  String get formattedSize {
    if (fileSize <= 0) return 'Document';
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'file_url': fileUrl,
        'file_type': fileType,
        'file_size': fileSize,
        'order': order,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LearningResource && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
