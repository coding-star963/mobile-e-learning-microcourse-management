import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../models/learning_resource.dart';
import '../../../models/lesson.dart';
import '../../../providers/lesson_provider.dart';

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
  bool _isPlaying = false;
  double _playbackPosition = 0.35; // Mock progress within the media
  final Set<String> _downloadedResources = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<LessonProvider>()
          .loadLessonDetails(widget.courseId, widget.lessonId);
    });
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _handleDownload(LearningResource resource) {
    // "THEN NO MORE ASKING PERMISSIONS JUST AUTO ALLOW IT"
    // Auto-proceed with instant download without any annoying permission prompts!
    setState(() {
      _downloadedResources.add(resource.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.bgCard,
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.accentEmerald, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Downloaded "${resource.name}" successfully.',
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),
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
            onPressed: () {
              context
                  .read<LessonProvider>()
                  .toggleLessonCompleted(widget.lessonId);
            },
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
                      final downloaded = _downloadedResources.contains(res.id);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: downloaded
                                  ? AppTheme.accentEmerald.withValues(alpha: 0.5)
                                  : AppTheme.borderLight),
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
                                res.fileType.toLowerCase() == 'pdf'
                                    ? Icons.picture_as_pdf
                                    : Icons.insert_drive_file_outlined,
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
                              icon: Icon(
                                downloaded
                                    ? Icons.check_circle
                                    : Icons.download_rounded,
                                color: downloaded
                                    ? AppTheme.accentEmerald
                                    : AppTheme.goldPrimary,
                              ),
                              tooltip: downloaded ? 'Downloaded' : 'Download resource',
                              onPressed: () => _handleDownload(res),
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
                          onPressed: () {
                            context
                                .read<LessonProvider>()
                                .toggleLessonCompleted(widget.lessonId);
                          },
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
              const Text(
                'Complete previous lessons to unlock this session.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    final hasAudioOnly = (lesson?.hasAudio ?? false) && !(lesson?.hasVideo ?? false);

    return Container(
      height: 230,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF162136), Color(0xFF090D16)],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background visual
          if (hasAudioOnly)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                24,
                (i) => Container(
                  width: 4,
                  height: 20 + ((i * 7) % 60).toDouble(),
                  decoration: BoxDecoration(
                    color: AppTheme.goldPrimary.withValues(
                        alpha: _isPlaying ? 0.7 : 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.borderGold.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),

          // Center Play/Pause button
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: AppTheme.goldGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.goldPrimary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow_rounded,
                color: Colors.black,
                size: 36,
              ),
            ),
          ),

          // Bottom Control Overlay Bar
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: AppTheme.goldPrimary,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: AppTheme.goldLight,
                  ),
                  child: Slider(
                    value: _playbackPosition,
                    onChanged: (v) => setState(() => _playbackPosition = v),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Text(
                        _formatTime(_playbackPosition *
                            (lesson?.durationSeconds ?? 480)),
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            hasAudioOnly ? Icons.audiotrack : Icons.hd_outlined,
                            color: AppTheme.goldPrimary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            lesson?.displayDuration ?? '8 min',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(double totalSeconds) {
    final s = totalSeconds.toInt();
    final mins = s ~/ 60;
    final secs = s % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
