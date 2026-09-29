import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/enrollment_provider.dart';
import '../../screens/course/catalog_view.dart';
import '../../screens/enrollment/my_courses_screen.dart';

/// Luxury Home Shell.
/// Features a luxury frosted navigation bar and gold accents.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final enrollmentCount =
        context.watch<EnrollmentProvider>().enrollments.length;

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
            const Text(
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
          IconButton(
            icon: const Icon(Icons.person_outline_rounded,
                color: AppTheme.goldPrimary),
            tooltip: 'My profile',
            onPressed: () => Navigator.of(context).pushNamed('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.textMuted),
            tooltip: 'Log out',
            onPressed: auth.isLoading ? null : () => _confirmLogout(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: const [
          CatalogView(),
          MyCoursesScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0E131F),
          border: Border(
            top: BorderSide(
              color: AppTheme.borderGold.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _tabIndex,
          onDestinationSelected: (index) => setState(() => _tabIndex = index),
          destinations: [
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
        title: const Text('End Session',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: const Text(
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
