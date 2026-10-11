import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auto_refresh.dart';
import '../../../core/theme.dart';
import '../../../data/repositories/course_repository.dart';
import '../../../models/course.dart';
import '../../../models/enrollment.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/course_provider.dart';
import '../../../providers/enrollment_provider.dart';
import '../../../providers/lesson_provider.dart';

/// 2.4 Luxury Course Details Screen.
/// Displays detailed masterclass information, curriculum roadmap,
/// objectives, and high-end enrollment action.
class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final String courseId;

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen>
    with AutoRefresh {
  Course? _course;
  bool _isLoading = true;
  String? _error;
  Enrollment? _myEnrollment;
  bool _isEnrollmentLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourse();
  }

  /// Picks up course edits and enrollment changes made on the web portal.
  /// Lessons are refreshed by the home shell through [LessonProvider].
  @override
  Future<void> onAutoRefresh() async {
    if (_course == null || !(ModalRoute.of(context)?.isCurrent ?? true)) return;
    try {
      final course = await context
          .read<CourseProvider>()
          .loadCourseDetails(widget.courseId);
      if (!mounted) return;
      setState(() => _course = course);
      await _loadEnrollmentState(forceRefresh: true);
    } on Exception catch (_) {
      // Keep showing the current details; the next refresh retries.
    }
  }

  Future<void> _loadCourse() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final course = await context
          .read<CourseProvider>()
          .loadCourseDetails(widget.courseId);
      if (!mounted) return;
      setState(() => _course = course);
      await _loadEnrollmentState();
      if (mounted) {
        try {
          context.read<LessonProvider>().loadLessons(widget.courseId);
        } catch (_) {}
      }
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is CourseNotFoundException
            ? 'This course could not be found.'
            : 'Could not load masterclass details. Please retry.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadEnrollmentState({bool forceRefresh = false}) async {
    AuthProvider? auth;
    try {
      auth = context.read<AuthProvider>();
    } catch (_) {}
    final user = auth?.user;
    if (user == null) return;
    try {
      final enrollment = await context
          .read<EnrollmentProvider>()
          .getEnrollmentForCourse(
            studentId: user.id,
            courseId: widget.courseId,
            forceRefresh: forceRefresh,
          );
      if (!mounted) return;
      setState(() {
        _myEnrollment = enrollment;
        _isEnrollmentLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isEnrollmentLoading = false);
    }
  }

  Future<void> _enroll() async {
    final user = context.read<AuthProvider>().user;
    if (user == null || _course == null) return;
    final enrollmentProvider = context.read<EnrollmentProvider>();
    final ok = await enrollmentProvider.enroll(
      studentId: user.id,
      courseId: _course!.id,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.bgCard,
        content: Row(
          children: [
            Icon(
              ok ? Icons.check_circle : Icons.error_outline,
              color: ok ? AppTheme.accentEmerald : AppTheme.accentRuby,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                ok
                    ? 'Enrolled in ${_course!.title}!'
                    : (enrollmentProvider.error ?? 'Could not enroll.'),
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
    if (ok) await _loadEnrollmentState();
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = context.watch<CourseProvider>();
    LessonProvider? lessonProvider;
    try {
      lessonProvider = context.watch<LessonProvider>();
    } catch (_) {}
    final lessons = lessonProvider?.lessonsFor(widget.courseId) ?? const [];
    final course = _course;

    return Scaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.goldPrimary),
            )
          : _error != null
              ? _buildErrorView()
              : RefreshIndicator(
                  color: AppTheme.goldPrimary,
                  backgroundColor: AppTheme.bgCard,
                  onRefresh: _loadCourse,
                  child: CustomScrollView(
                    slivers: [
                      // -- Luxury Hero Banner Header -------------------------
                      SliverAppBar(
                        expandedHeight: 240,
                        pinned: true,
                        title: Text(
                          course!.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        flexibleSpace: FlexibleSpaceBar(
                          background: _buildHeroBanner(course, courseProvider),
                        ),
                      ),

                      // -- Main Content --------------------------------------
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 130),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status & Title Row
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: course.isPublished
                                          ? AppTheme.accentEmerald
                                              .withValues(alpha: 0.15)
                                          : AppTheme.accentRuby
                                              .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: course.isPublished
                                            ? AppTheme.accentEmerald
                                                .withValues(alpha: 0.4)
                                            : AppTheme.accentRuby
                                                .withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          course.isPublished
                                              ? Icons.check_circle_outline
                                              : Icons.lock_outline,
                                          size: 13,
                                          color: course.isPublished
                                              ? AppTheme.accentEmerald
                                              : AppTheme.accentRuby,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          course.isPublished
                                              ? 'Open'
                                              : 'Draft',
                                          style: TextStyle(
                                            color: course.isPublished
                                                ? AppTheme.accentEmerald
                                                : AppTheme.accentRuby,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 10,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    course.difficultyLevel,
                                    style: TextStyle(
                                      color: AppTheme.difficultyColor(
                                          course.difficultyLevel),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              Text(
                                course.title,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),

                              Text(
                                '${courseProvider.categoryNameOf(course.categoryId)} • ${course.difficultyLevel}',
                                style: const TextStyle(
                                  color: AppTheme.goldLight,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Description Card
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: AppTheme.luxuryCardDecoration,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.info_outline,
                                            color: AppTheme.goldPrimary,
                                            size: 18),
                                        SizedBox(width: 8),
                                        Text(
                                          'About this course',
                                          style: TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      course.description,
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Objectives
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: AppTheme.luxuryCardDecoration,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.auto_awesome_outlined,
                                            color: AppTheme.goldPrimary,
                                            size: 18),
                                        SizedBox(width: 8),
                                        Text(
                                          'What you will learn',
                                          style: TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    for (final obj in course.objectives)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 10),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 20,
                                              height: 20,
                                              margin: const EdgeInsets.only(
                                                  right: 10, top: 2),
                                              decoration: BoxDecoration(
                                                color: AppTheme.goldPrimary
                                                    .withValues(alpha: 0.15),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.check,
                                                size: 12,
                                                color: AppTheme.goldPrimary,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                obj,
                                                style: const TextStyle(
                                                  color: AppTheme.textPrimary,
                                                  fontSize: 13,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Curriculum summary
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: AppTheme.luxuryCardDecoration,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.layers_outlined,
                                            color: AppTheme.goldPrimary,
                                            size: 18),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Curriculum Modules',
                                          style: TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${course.lessonIds.length} lesson(s) in this course.',
                                          style: const TextStyle(
                                            color: AppTheme.textMuted,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    if (lessons.isEmpty)
                                      const Text(
                                        'Modules are being scheduled by the instructor.',
                                        style: TextStyle(
                                            color: AppTheme.textMuted,
                                            fontSize: 13),
                                      )
                                    else
                                      ...lessons.take(3).map((l) => Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.play_circle_outline,
                                                  size: 16,
                                                  color: AppTheme.goldPrimary,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    l.title,
                                                    style: const TextStyle(
                                                      color: AppTheme.textSecondary,
                                                      fontSize: 13,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  l.displayDuration,
                                                  style: const TextStyle(
                                                    color: AppTheme.textMuted,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )),
                                    if (lessons.length > 3)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          '+ ${lessons.length - 3} more modules in curriculum',
                                          style: const TextStyle(
                                            color: AppTheme.goldLight,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

      // -- Sticky Luxury Bottom Action Bar ----------------------------------
      bottomNavigationBar: (_isLoading || _error != null)
          ? null
          : Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: MediaQuery.of(context).padding.bottom + 14,
              ),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                border: const Border(
                  top: BorderSide(color: AppTheme.borderLight),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: _isEnrollmentLoading
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.goldPrimary,
                        ),
                      ),
                    )
                  : _myEnrollment != null
                      ? Container(
                          decoration: BoxDecoration(
                            gradient: AppTheme.goldGradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.black,
                              shadowColor: Colors.transparent,
                              minimumSize: const Size.fromHeight(50),
                            ),
                            icon: const Icon(Icons.play_arrow_rounded, size: 22),
                            label: const Text(
                              'Continue learning',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pushNamed(
                              '/course-workspace',
                              arguments: course!.id,
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: course!.isPublished
                                ? AppTheme.goldGradient
                                : null,
                            color:
                                course.isPublished ? null : AppTheme.bgSurface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: course.isPublished
                                  ? Colors.black
                                  : AppTheme.textMuted,
                              shadowColor: Colors.transparent,
                              minimumSize: const Size.fromHeight(50),
                            ),
                            icon: const Icon(Icons.workspace_premium_outlined),
                            label: Text(
                              course.isPublished
                                  ? 'Enroll in this course'
                                  : 'Not open for enrollment',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            onPressed: course.isPublished ? _enroll : null,
                          ),
                        ),
            ),
    );
  }

  Widget _buildHeroBanner(Course course, CourseProvider courseProvider) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF22304C), Color(0xFF0C121E)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (course.thumbnailUrl != null && course.thumbnailUrl!.isNotEmpty)
            Image.network(
              course.thumbnailUrl!,
              fit: BoxFit.cover,
              // On web, /storage files have no CORS headers.
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
              errorBuilder: (_, _, _) => const SizedBox(),
            ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  AppTheme.bgDark.withValues(alpha: 0.95),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Text(
              course.title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 52, color: AppTheme.accentRuby),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loadCourse,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
