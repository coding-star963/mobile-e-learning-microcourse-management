import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../models/student_dashboard.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../widgets/announcement_tile.dart';
import '../../widgets/progress_bar.dart';
import '../progress/learning_history_screen.dart';

/// 7.1 Student Dashboard — overview of courses, progress, recent activity
/// (7.2 My Courses Summary, 7.3 Progress Summary, 7.4 Recent Announcements,
/// 5.5 Continue Learning).
class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key, this.onOpenAnnouncements});

  /// Switches the home shell to the announcements tab.
  final VoidCallback? onOpenAnnouncements;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final user = context.watch<AuthProvider>().user;
    final data = provider.dashboard;

    Future<void> refresh() => provider.load(user?.id ?? '');

    void openCourse(String courseId) {
      Navigator.of(context).pushNamed('/course-workspace', arguments: courseId).then((_) => refresh());
    }

    return RefreshIndicator(
      color: AppTheme.goldPrimary,
      onRefresh: refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Text(
            'Hi, ${user?.fullName.split(' ').first ?? 'there'}!',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text('Here is your learning at a glance.', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          if (data == null && provider.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary)),
            )
          else if (data == null)
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Column(
                children: [
                  Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.textMuted),
                  const SizedBox(height: 12),
                  Text(provider.error ?? 'Pull down to load your dashboard.',
                      textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted)),
                  TextButton(onPressed: refresh, child: const Text('Retry')),
                ],
              ),
            )
          else ...[
            // 7.3 Progress Summary
            _SummaryGrid(data: data),
            const SizedBox(height: 20),

            // 5.5 Continue Learning
            if (data.continueLearning != null) ...[
              const _SectionTitle('Continue learning'),
              _ContinueCard(course: data.continueLearning!, onTap: () => openCourse(data.continueLearning!.courseId)),
              const SizedBox(height: 20),
            ],

            // 7.2 My Courses Summary
            const _SectionTitle('My courses'),
            if (data.courses.isEmpty)
              Text('You have not enrolled in a course yet. Browse the Courses tab to get started.',
                  style: TextStyle(color: AppTheme.textMuted))
            else
              ...data.courses.map((c) => _CourseProgressTile(course: c, onTap: () => openCourse(c.courseId))),
            const SizedBox(height: 20),

            // 7.4 Recent Announcements
            Row(
              children: [
                const Expanded(child: _SectionTitle('Recent announcements')),
                if (onOpenAnnouncements != null)
                  TextButton(onPressed: onOpenAnnouncements, child: const Text('See all')),
              ],
            ),
            if (data.recentAnnouncements.isEmpty)
              Text('No announcements yet.', style: TextStyle(color: AppTheme.textMuted))
            else
              ...data.recentAnnouncements.take(3).map((a) => AnnouncementTile(announcement: a)),
            const SizedBox(height: 20),

            // 7.1 Recent learning activity / 5.4 Learning History
            Row(
              children: [
                const Expanded(child: _SectionTitle('Recent activity')),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LearningHistoryScreen()),
                  ),
                  child: const Text('Learning history'),
                ),
              ],
            ),
            if (data.recentActivity.isEmpty)
              Text('Complete a lesson to see it here.', style: TextStyle(color: AppTheme.textMuted))
            else
              ...data.recentActivity.map((a) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.check_circle, color: AppTheme.accentEmerald),
                    title: Text(a.lessonTitle, style: TextStyle(color: AppTheme.textPrimary)),
                    subtitle: Text(
                      '${a.courseTitle}${a.completedAt != null ? ' • ${formatShortDate(a.completedAt!)}' : ''}',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  )),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
      );
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.data});

  final StudentDashboard data;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      ('Enrolled', '${data.enrolledCourses}', Icons.bookmark_rounded),
      ('In progress', '${data.inProgressCourses}', Icons.timelapse_rounded),
      ('Completed', '${data.completedCourses}', Icons.emoji_events_outlined),
      ('Avg. progress', '${data.averageProgress.round()}%', Icons.trending_up_rounded),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.1,
      children: [
        for (final (label, value, icon) in tiles)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: AppTheme.luxuryCardDecoration,
            child: Row(
              children: [
                Icon(icon, color: AppTheme.goldPrimary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(value,
                          style: TextStyle(
                              color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                      Text(label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.course, required this.onTap});

  final DashboardCourse course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: AppTheme.goldGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(course.title,
                style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              course.nextLessonTitle != null ? 'Next: ${course.nextLessonTitle}' : 'Pick up where you left off',
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: course.progress / 100,
                      minHeight: 6,
                      backgroundColor: Colors.black12,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${course.progress.round()}%',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
                const SizedBox(width: 8),
                const Icon(Icons.play_circle_fill_rounded, color: Colors.black),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseProgressTile extends StatelessWidget {
  const _CourseProgressTile({required this.course, required this.onTap});

  final DashboardCourse course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.luxuryCardDecoration,
      child: ListTile(
        onTap: onTap,
        title: Text(course.title,
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: ProgressBar(
            fraction: course.progress / 100,
            label: course.isCompleted
                ? 'Completed • ${course.totalLessons} lessons'
                : '${course.completedLessons} of ${course.totalLessons} lessons • ${course.progress.round()}%',
          ),
        ),
        trailing: Icon(
          course.isCompleted ? Icons.emoji_events_rounded : Icons.chevron_right_rounded,
          color: course.isCompleted ? AppTheme.accentEmerald : AppTheme.textMuted,
        ),
      ),
    );
  }
}
