import 'learning_resource.dart';

/// Lesson model for Module 4 (Lesson & Learning Content, 4.1–4.6)
/// and Module 5 (Learning Progress, 5.1).
/// Pure Dart: no Flutter imports (AGENT.md §7).
class Lesson {
  const Lesson({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    this.status = 'published',
    this.availability = 'free',
    this.order = 1,
    this.videoUrl,
    this.audioUrl,
    this.videoType,
    this.audioType,
    this.videoSize,
    this.audioSize,
    this.durationSeconds = 0,
    this.durationFormatted,
    this.isFreePreview = false,
    this.resources = const [],
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    var rawResources = json['resources'];
    List<LearningResource> parsedResources = [];
    if (rawResources is List) {
      parsedResources = rawResources
          .map((r) => LearningResource.fromJson(r as Map<String, dynamic>))
          .toList();
    }

    return Lesson(
      id: json['id']?.toString() ?? '',
      courseId: (json['courseId'] ?? json['course_id'])?.toString() ?? '',
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      status: (json['status'] ?? 'published') as String,
      availability: (json['availability'] ?? 'free') as String,
      order: (json['order'] ?? 1) as int,
      videoUrl: (json['videoUrl'] ?? json['video_url']) as String?,
      audioUrl: (json['audioUrl'] ?? json['audio_url']) as String?,
      videoType: (json['videoType'] ?? json['video_type']) as String?,
      audioType: (json['audioType'] ?? json['audio_type']) as String?,
      videoSize: (json['videoSize'] ?? json['video_size']) as int?,
      audioSize: (json['audioSize'] ?? json['audio_size']) as int?,
      durationSeconds: (json['durationSeconds'] ?? json['duration_seconds'] ?? 0) as int,
      durationFormatted: (json['durationFormatted'] ?? json['duration_formatted']) as String?,
      isFreePreview: (json['isFreePreview'] ?? json['is_free_preview'] ?? false) as bool,
      resources: parsedResources,
    );
  }

  final String id;
  final String courseId;
  final String title;
  final String description;
  final String status;
  final String availability; // 'free', 'locked', 'scheduled'
  final int order;
  final String? videoUrl;
  final String? audioUrl;
  final String? videoType;
  final String? audioType;
  final int? videoSize;
  final int? audioSize;
  final int durationSeconds;
  final String? durationFormatted;
  final bool isFreePreview;
  final List<LearningResource> resources;

  bool get isLocked => availability.toLowerCase() == 'locked';
  bool get isFree => availability.toLowerCase() == 'free' || isFreePreview;
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;
  bool get hasAudio => audioUrl != null && audioUrl!.isNotEmpty;
  bool get hasMedia => hasVideo || hasAudio;

  String get displayDuration {
    if (durationFormatted != null && durationFormatted!.isNotEmpty) {
      return durationFormatted!;
    }
    if (durationSeconds <= 0) return '5 min';
    final mins = durationSeconds ~/ 60;
    final secs = durationSeconds % 60;
    if (mins == 0) return '$secs sec';
    return '$mins min ${secs > 0 ? '$secs sec' : ''}';
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'course_id': courseId,
        'title': title,
        'description': description,
        'status': status,
        'availability': availability,
        'order': order,
        'video_url': videoUrl,
        'audio_url': audioUrl,
        'video_type': videoType,
        'audio_type': audioType,
        'video_size': videoSize,
        'audio_size': audioSize,
        'duration_seconds': durationSeconds,
        'duration_formatted': durationFormatted,
        'is_free_preview': isFreePreview,
        'resources': resources.map((r) => r.toJson()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Lesson && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
