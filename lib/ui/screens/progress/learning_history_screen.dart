import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/progress_provider.dart';
import '../../widgets/announcement_tile.dart';

/// 5.4 View Learning History — completed courses and every completed lesson.
class LearningHistoryScreen extends StatefulWidget {
  const LearningHistoryScreen({super.key});

  @override
  State<LearningHistoryScreen> createState() => _LearningHistoryScreenState();
}

class _LearningHistoryScreenState extends State<LearningHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final studentId = context.read<AuthProvider>().user?.id;
    if (studentId != null) {
      await context.read<ProgressProvider>().loadHistory(studentId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final completedCourses =
        context.watch<DashboardProvider>().dashboard?.courses.where((c) => c.isCompleted).toList() ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Learning History')),
      body: RefreshIndicator(
        color: AppTheme.goldPrimary,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const Text('Completed courses',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            if (completedCourses.isEmpty)
              const Text('No completed courses yet.', style: TextStyle(color: AppTheme.textMuted))
            else
              ...completedCourses.map((c) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.emoji_events_rounded, color: AppTheme.goldPrimary),
                    title: Text(c.title, style: const TextStyle(color: AppTheme.textPrimary)),
                    subtitle: Text('${c.totalLessons} lessons completed',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  )),
            const SizedBox(height: 20),
            const Text('Completed lessons',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            if (progress.isLoading && progress.history.isEmpty)
              const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary))
            else if (progress.error != null)
              Text(progress.error!, style: const TextStyle(color: AppTheme.accentRuby))
            else if (progress.history.isEmpty)
              const Text('No completed lessons yet.', style: TextStyle(color: AppTheme.textMuted))
            else
              ...progress.history.map((a) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.check_circle, color: AppTheme.accentEmerald),
                    title: Text(a.lessonTitle, style: const TextStyle(color: AppTheme.textPrimary)),
                    subtitle: Text(
                      '${a.courseTitle}${a.completedAt != null ? ' • ${formatShortDate(a.completedAt!)}' : ''}',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
