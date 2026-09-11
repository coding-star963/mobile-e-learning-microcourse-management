import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/enrollment_provider.dart';
import '../../screens/course/catalog_view.dart';
import '../../screens/enrollment/my_courses_screen.dart';

/// Home shell after login: hosts the course catalog (Module 2) and My Courses
/// (Module 3) tabs, plus persistent entry points for 1.2 Logout and 1.4
/// Profile. The dashboard (Module 7) will extend this shell in Sprint 7.
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
        title: const Text('MicroLearn'),
        actions: [
          IconButton(
            // 1.4 Profile Management entry point.
            icon: const Icon(Icons.person_outline),
            tooltip: 'My profile',
            onPressed: () => Navigator.of(context).pushNamed('/profile'),
          ),
          IconButton(
            // 1.2 Logout.
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: auth.isLoading ? null : () => _confirmLogout(context),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: const [
          CatalogView(), // 2.1–2.5
          MyCoursesScreen(), // 3.2–3.4
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Courses',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('$enrollmentCount'),
              isLabelVisible: enrollmentCount > 0,
              child: const Icon(Icons.bookmark_border_outlined),
            ),
            selectedIcon: const Icon(Icons.bookmark),
            label: 'My Courses',
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Do you want to end your session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      // 1.2 Logout — AuthGate navigates back to the login screen.
      await context.read<AuthProvider>().logout();
    }
  }
}
