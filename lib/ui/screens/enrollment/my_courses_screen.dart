import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/enrollment.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/course_provider.dart';
import '../../../providers/enrollment_provider.dart';
import '../../widgets/progress_bar.dart';

/// 3.2 View Enrolled Courses — the student's enrollments with progress and
/// status. Body-only widget: embedded as the home shell's "My Courses" tab
/// and wrapped by [MyCoursesPage] for the standalone route. Tapping opens
/// the enrollment details (3.3).
class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

/// Standalone route wrapper for [MyCoursesScreen].
class MyCoursesPage extends StatelessWidget {
  const MyCoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Courses')),
      body: const MyCoursesScreen(),
    );
  }
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  String? _loadedForUserId;

  /// Loads (or reloads) enrollments whenever the signed-in user changes.
  /// [didChangeDependencies] fires on every Provider update, so guard with
  /// the user id to avoid reload loops. The load is deferred to after the
  /// current frame because it triggers provider notifications.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadIfNeeded());
  }

  void _loadIfNeeded() {
    final user = context.read<AuthProvider>().user;
    if (user == null || _loadedForUserId == user.id) return;
    _loadedForUserId = user.id;
    context.read<EnrollmentProvider>().loadEnrollments(user.id);
  }

  @override
  Widget build(BuildContext context) {
    final enrollmentProvider = context.watch<EnrollmentProvider>();
    final courseProvider = context.watch<CourseProvider>();
    final theme = Theme.of(context);

    return enrollmentProvider.isLoading
        ? const Center(child: CircularProgressIndicator())
        : enrollmentProvider.error != null
            ? Center(
                child: Text(
                  enrollmentProvider.error!,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              )
            : enrollmentProvider.enrollments.isEmpty
                ? const _EmptyState()
                : RefreshIndicator(
                    onRefresh: () async {
                      final user = context.read<AuthProvider>().user;
                      if (user != null) {
                        await context
                            .read<EnrollmentProvider>()
                            .loadEnrollments(user.id);
                      }
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: enrollmentProvider.enrollments.length,
                      itemBuilder: (context, index) {
                        final enrollment =
                            enrollmentProvider.enrollments[index];
                        return _EnrollmentCard(
                          key: ValueKey(enrollment.id),
                          enrollment: enrollment,
                          courseProvider: courseProvider,
                        );
                      },
                    ),
                  );
  }
}

/// Enrollment card with thumbnail, title, status pill, and progress (3.2).
class _EnrollmentCard extends StatelessWidget {
  const _EnrollmentCard({
    super.key,
    required this.enrollment,
    required this.courseProvider,
  });

  final Enrollment enrollment;
  final CourseProvider courseProvider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Catalog lookup first, then the detail cache (AGENT.md §4.4 — all data
    // via providers).
    final course = courseProvider.courseById(enrollment.courseId);
    final totalLessons = course?.lessonIds.length ?? 0;
    final fraction = enrollment.progressFraction(totalLessons);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).pushNamed(
          '/enrollment-detail',
          arguments: enrollment.id,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail for quick recognition (reuses 2.4 data).
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: Image.network(
                    course?.thumbnailUrl ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _thumbPlaceholder(theme),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            course?.title ?? enrollment.courseId,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _StatusPill(status: enrollment.status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Enrolled ${_formatDate(enrollment.enrolledAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ProgressBar(
                      fraction: fraction,
                      label:
                          '${enrollment.completedLessonIds.length} of $totalLessons lessons completed',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  Widget _thumbPlaceholder(ThemeData theme) => ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Icon(Icons.school_outlined, color: theme.colorScheme.outline),
      );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final EnrollmentStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = status == EnrollmentStatus.completed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: completed
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        completed ? 'Completed' : 'In progress',
        style: theme.textTheme.labelSmall?.copyWith(
          color: completed
              ? theme.colorScheme.onPrimaryContainer
              : theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bookmark_border_outlined,
                size: 44, color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 16),
          Text(
            'You have not enrolled in any courses yet.',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Browse the catalog and enroll to start learning.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            icon: const Icon(Icons.explore_outlined),
            label: const Text('Browse courses'),
          ),
        ],
      ),
    );
  }
}
