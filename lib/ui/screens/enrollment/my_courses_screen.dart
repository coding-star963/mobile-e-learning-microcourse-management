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
                  ? _EmptyState(theme: theme)
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
                        padding: const EdgeInsets.all(16),
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
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).pushNamed(
          '/enrollment-detail',
          arguments: enrollment.id,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      course?.title ?? enrollment.courseId,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _StatusPill(status: enrollment.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Enrolled ${_formatDate(enrollment.enrolledAt)}'
                '${totalLessons > 0 ? ' • $totalLessons lessons' : ''}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
              const SizedBox(height: 12),
              ProgressBar(
                fraction: fraction,
                label:
                    '${enrollment.completedLessonIds.length} of $totalLessons lessons completed',
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
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final EnrollmentStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = status == EnrollmentStatus.completed;
    return Chip(
      label: Text(
        completed ? 'Completed' : 'In progress',
        style: theme.textTheme.labelSmall?.copyWith(
          color: completed
              ? theme.colorScheme.onPrimaryContainer
              : theme.colorScheme.onSecondaryContainer,
        ),
      ),
      backgroundColor: completed
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.secondaryContainer,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border_outlined,
              size: 56, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text('You have not enrolled in any courses yet.',
              style: theme.textTheme.bodyLarge),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('Browse courses'),
          ),
        ],
      ),
    );
  }
}
