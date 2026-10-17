import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auto_refresh.dart';
import '../../../core/constants.dart';
import '../../../core/live_sync.dart';
import '../../../core/theme.dart';
import '../../../providers/announcement_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/course_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/enrollment_provider.dart';
import '../../../providers/lesson_provider.dart';
import '../../screens/course/catalog_view.dart';
import '../../widgets/theme_toggle_button.dart';
import '../../screens/enrollment/my_courses_screen.dart';
import '../notifications/announcements_screen.dart';
import '../notifications/notifications_screen.dart';
import 'student_dashboard_screen.dart';

/// Luxury Home Shell.
/// Features a luxury frosted navigation bar and gold accents.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with AutoRefresh {
  int _tabIndex = 0;

  /// Live-sync marker the providers were last reloaded for.
  String? _syncedVersion;
  DateTime? _lastFullRefresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOverview());
  }

  /// Keeps every tab, the notification bell and any open lesson screens in
  /// sync with changes made on the web portal. The shell stays mounted under
  /// pushed screens, so this also runs while a course or lesson is open.
  @override
  Future<void> onAutoRefresh() async {
    final auth = context.read<AuthProvider>();
    final studentId = auth.user?.id;
    if (studentId == null) return;
    final navigator = Navigator.of(context);
    final dashboard = context.read<DashboardProvider>();
    final announcements = context.read<AnnouncementProvider>();
    final courses = context.read<CourseProvider>();
    final enrollments = context.read<EnrollmentProvider>();
    final lessons = context.read<LessonProvider>();

    // e.g. a teacher suspended or an administrator deactivated this student.
    final check = await auth.checkSession();
    if (!check.valid) {
      navigator.popUntil((route) => route.isFirst);
      auth.endRejectedSession(check.message);
      return;
    }

    // Reload only when the server's data changed (or as a periodic safety net).
    final now = DateTime.now();
    final recentlyRefreshed = _lastFullRefresh != null &&
        now.difference(_lastFullRefresh!) < AppConstants.fullRefreshInterval;
    if (check.version != null && check.version == _syncedVersion && recentlyRefreshed) {
      return;
    }

    await Future.wait([
      dashboard.load(studentId, silent: true),
      announcements.load(studentId, silent: true),
      courses.refresh(),
      enrollments.loadEnrollments(studentId, silent: true),
      lessons.refreshLoaded(),
    ]);
    _syncedVersion = check.version;
    _lastFullRefresh = now;
    LiveSync.bump();
    _announceNewNotices(announcements);
  }

  /// Ids of personal notices already on screen (null until the first load).
  Set<String>? _knownNoticeIds;

  /// Pops up a teacher's enrollment action (suspended, cancelled, deleted…)
  /// the moment it arrives; it also stays in Notifications.
  void _announceNewNotices(AnnouncementProvider provider) {
    final notices = provider.announcements.where((a) => a.isEnrollmentNotice).toList();
    final known = _knownNoticeIds;
    _knownNoticeIds = notices.map((a) => a.id).toSet();
    if (known == null || !mounted) return;

    final fresh = notices.where((a) => !known.contains(a.id)).toList();
    if (fresh.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.bgCard,
        duration: const Duration(seconds: 6),
        content: Text(
          fresh.length == 1
              ? '${fresh.first.title}: ${fresh.first.content}'
              : 'You have ${fresh.length} new enrollment updates.',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        action: SnackBarAction(
          label: 'View',
          textColor: AppTheme.goldPrimary,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
        ),
      ),
    );
  }

  /// 7.1 dashboard and 6.3 notification count for the signed-in student.
  void _loadOverview() {
    final studentId = context.read<AuthProvider>().user?.id;
    if (studentId == null) return;
    context.read<DashboardProvider>().load(studentId);
    context.read<AnnouncementProvider>().load(studentId);
  }

  void _selectTab(int index) {
    setState(() => _tabIndex = index);
    if (index == 0) {
      final studentId = context.read<AuthProvider>().user?.id;
      if (studentId != null) context.read<DashboardProvider>().load(studentId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final enrollmentCount =
        context.watch<EnrollmentProvider>().enrollments.length;
    final unreadCount = context.watch<AnnouncementProvider>().unreadCount;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.goldGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.goldPrimary.withValues(alpha: 0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_stories,
                size: 18,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'MicroLearn',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppTheme.borderGold.withValues(alpha: 0.2),
            height: 1,
          ),
        ),
        actions: [
          // 6.3 View Notifications
          IconButton(
            icon: Badge(
              label: Text('$unreadCount'),
              isLabelVisible: unreadCount > 0,
              child: const Icon(Icons.notifications_none_rounded, color: AppTheme.goldPrimary),
            ),
            tooltip: 'Notifications',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded,
                color: AppTheme.goldPrimary),
            tooltip: 'My profile',
            onPressed: () => Navigator.of(context).pushNamed('/profile'),
          ),
          IconButton(
            icon: Icon(Icons.logout_rounded, color: AppTheme.textMuted),
            tooltip: 'Log out',
            onPressed: auth.isLoading ? null : () => _confirmLogout(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          StudentDashboardScreen(onOpenAnnouncements: () => _selectTab(3)),
          const CatalogView(),
          const MyCoursesScreen(),
          const AnnouncementsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.navBar,
          border: Border(
            top: BorderSide(
              color: AppTheme.borderGold.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _tabIndex,
          onDestinationSelected: _selectTab,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard, color: AppTheme.goldPrimary),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore, color: AppTheme.goldPrimary),
              label: 'Courses',
            ),
            NavigationDestination(
              icon: Badge(
                label: Text(
                  '$enrollmentCount',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                backgroundColor: AppTheme.goldPrimary,
                isLabelVisible: enrollmentCount > 0,
                child: const Icon(Icons.bookmark_border_rounded),
              ),
              selectedIcon: const Icon(Icons.bookmark_rounded,
                  color: AppTheme.goldPrimary),
              label: 'My Courses',
            ),
            const NavigationDestination(
              icon: Icon(Icons.campaign_outlined),
              selectedIcon: Icon(Icons.campaign, color: AppTheme.goldPrimary),
              label: 'Updates',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.borderGold),
        ),
        title: Text('End Session',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to sign out from your executive account?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accentRuby,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }
}
