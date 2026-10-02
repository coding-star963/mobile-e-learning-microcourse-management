import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme.dart';
import '../../../models/learning_resource.dart';
import '../../../models/lesson.dart';
import '../../../providers/lesson_provider.dart';
import '../../widgets/lesson_media_player.dart';

/// Module 4: Lesson Detail & Multimedia Player Screen (4.2, 4.3, 4.4, 5.1).
/// Features a luxury cinematic player, instant resource access, and lesson completion.
class LessonDetailScreen extends StatefulWidget {
  const LessonDetailScreen({
    super.key,
    required this.courseId,
    required this.lessonId,
  });

  final String courseId;
  final String lessonId;

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<LessonProvider>()
          .loadLessonDetails(widget.courseId, widget.lessonId);
    });
  }

  /// 5.1 Track Lesson Completion — tells the student if saving failed.
  Future<void> _toggleCompleted() async {
    final lessonProvider = context.read<LessonProvider>();
    final saved = await lessonProvider.toggleLessonCompleted(widget.lessonId);
    if (!saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lessonProvider.error ?? 'Could not save your progress.')),
      );
    }
  }

  /// 4.4 View/Download Learning Resources — opens the file in the browser or a
  /// viewer app, where the student can read or save it.
  Future<void> _openResource(LearningResource resource) async {
    final url = resource.fileUrl;
    var opened = false;
    if (url != null && url.isNotEmpty) {
      try {
        opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } catch (_) {
        opened = false;
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(opened
            ? 'Opening "${resource.name}"...'
            : 'Could not open "${resource.name}".'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lessonProvider = context.watch<LessonProvider>();
    final lesson = lessonProvider.cachedLesson(widget.lessonId);
    final allLessons = lessonProvider.lessonsFor(widget.courseId);
    final currentIndex =
        allLessons.indexWhere((l) => l.id == widget.lessonId);
    final nextLesson = (currentIndex >= 0 && currentIndex < allLessons.length - 1)
        ? allLessons[currentIndex + 1]
        : null;
    final isDone = lessonProvider.isCompleted(widget.lessonId);

    if (lesson == null && lessonProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.goldPrimary),
        ),
      );
    }

    final title = lesson?.title ?? 'Lesson Detail';
    final description = lesson?.description ?? 'No description available.';
    final isLocked = lesson?.isLocked ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(
              isDone ? Icons.check_circle : Icons.check_circle_outline,
              color: isDone ? AppTheme.accentEmerald : AppTheme.textMuted,
            ),
            tooltip: isDone ? 'Mark as incomplete' : 'Mark as complete',
            onPressed: _toggleCompleted,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // -- 4.3 Luxury Cinematic Media Player -----------------------------
            _buildMediaPlayer(lesson, isLocked),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Metadata row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.goldPrimary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppTheme.goldPrimary.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          lesson?.availability.toUpperCase() ?? 'FREE',
                          style: const TextStyle(
                            color: AppTheme.goldPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.schedule, size: 14, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        lesson?.displayDuration ?? '8 min',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                      ),
                      const Spacer(),
                      if (isDone)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentEmerald.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.done_all,
                                  color: AppTheme.accentEmerald, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'COMPLETED',
                                style: TextStyle(
                                  color: AppTheme.accentEmerald,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Description
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // -- 4.4 Learning Resources Section -----------------------
                  Row(
                    children: [
                      const Icon(Icons.folder_open,
                          color: AppTheme.goldPrimary, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Learning Resources',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${lesson?.resources.length ?? 0} files',
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (lesson == null || lesson.resources.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: const Center(
                        child: Text(
                          'No downloadable resources attached to this lesson.',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ...lesson.resources.map((res) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.bgSurface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _resourceIcon(res.fileType),
                                color: AppTheme.goldPrimary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    res.name,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${res.fileType.toUpperCase()} • ${res.formattedSize}',
                                    style: const TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.download_rounded,
                                  color: AppTheme.goldPrimary),
                              tooltip: 'Open or download resource',
                              onPressed: () => _openResource(res),
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 32),

                  // Action Buttons: Mark Complete & Next Lesson
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(
                            isDone ? Icons.undo : Icons.check,
                            size: 18,
                          ),
                          label: Text(
                              isDone ? 'Mark Undone' : 'Mark Completed'),
                          onPressed: _toggleCompleted,
                        ),
                      ),
                      if (nextLesson != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.arrow_forward, size: 18),
                            label: const Text('Next Lesson'),
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => LessonDetailScreen(
                                    courseId: widget.courseId,
                                    lessonId: nextLesson.id,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPlayer(Lesson? lesson, bool isLocked) {
    if (isLocked) {
      return Container(
        height: 220,
        color: AppTheme.bgCard,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.bgSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.borderGold),
                ),
                child: const Icon(Icons.lock_outline,
                    color: AppTheme.goldPrimary, size: 28),
              ),
              const SizedBox(height: 12),
              const Text(
                'Lesson Locked',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                lesson?.lockedReason ?? 'This lesson is not available yet.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (lesson == null || !lesson.hasMedia) {
      return Container(
        height: 120,
        color: AppTheme.bgCard,
        alignment: Alignment.center,
        child: const Text(
          'This lesson has no video or audio. See the notes and resources below.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
      );
    }

    // 4.3 Play Video/Audio
    final url = lesson.hasVideo ? lesson.videoUrl! : lesson.audioUrl!;
    return LessonMediaPlayer(
      key: ValueKey(url),
      url: url,
      isAudio: !lesson.hasVideo,
      durationLabel: lesson.displayDuration,
    );
  }

  static IconData _resourceIcon(String fileType) {
    final type = fileType.toLowerCase();
    if (type.contains('pdf')) return Icons.picture_as_pdf;
    if (type.contains('image')) return Icons.image_outlined;
    if (type.contains('video')) return Icons.movie_outlined;
    if (type.contains('audio')) return Icons.audiotrack;
    return Icons.insert_drive_file_outlined;
  }
}
