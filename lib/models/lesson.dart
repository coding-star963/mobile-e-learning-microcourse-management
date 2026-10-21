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
    this.availableAt,
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
    this.isCompleted = false,
    this.quizTitle,
    this.quizQuestionCount = 0,
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
      availableAt: DateTime.tryParse(
          (json['availableAt'] ?? json['available_at'])?.toString() ?? '')?.toLocal(),
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
      isCompleted: (json['isCompleted'] ?? json['is_completed'] ?? false) as bool,
      resources: parsedResources,
      quizTitle: (json['quiz'] as Map?)?['title'] as String?,
      quizQuestionCount: (json['quiz'] as Map?)?['question_count'] as int? ?? 0,
    );
  }

  final String id;
  final String courseId;
  final String title;
  final String description;
  final String status;
  final String availability; // 'free', 'locked', 'scheduled'

  /// When a 'scheduled' lesson opens to students (4.6).
  final DateTime? availableAt;
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

  /// 5.1 Whether the signed-in student has completed this lesson (from the server).
  final bool isCompleted;
  final String? quizTitle;
  final int quizQuestionCount;
  bool get hasQuiz => quizTitle != null;

  /// 4.6 View Lesson Availability — locked by the teacher, or scheduled for later.
  bool get isLocked {
    switch (availability.toLowerCase()) {
      case 'locked':
        return true;
      case 'scheduled':
        return availableAt == null || availableAt!.isAfter(DateTime.now());
      default:
        return false;
    }
  }

  /// Why a locked lesson cannot be opened yet.
  String get lockedReason {
    if (availability.toLowerCase() == 'scheduled' && availableAt != null) {
      final d = availableAt!;
      String two(int n) => n.toString().padLeft(2, '0');
      return 'Opens on ${d.year}-${two(d.month)}-${two(d.day)} at ${two(d.hour)}:${two(d.minute)}.';
    }
    return 'An administrator has not opened this lesson yet.';
  }
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
        'available_at': availableAt?.toUtc().toIso8601String(),
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
        'is_completed': isCompleted,
        'quiz': hasQuiz ? {'title': quizTitle, 'question_count': quizQuestionCount} : null,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Lesson && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
