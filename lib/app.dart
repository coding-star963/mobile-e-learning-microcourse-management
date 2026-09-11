import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'ui/screens/auth/forgot_password_screen.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/auth/profile_screen.dart';
import 'ui/screens/course/course_detail_screen.dart';
import 'ui/screens/course/course_list_screen.dart';
import 'ui/screens/dashboard/home_shell.dart';
import 'ui/screens/enrollment/course_workspace_screen.dart';
import 'ui/screens/enrollment/enrollment_detail_screen.dart';
import 'ui/screens/enrollment/my_courses_screen.dart';

/// Root widget: MaterialApp, theme, and named routes (AGENT.md §4.2).
class MicroLearnApp extends StatelessWidget {
  const MicroLearnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MicroLearn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/',
      routes: {
        '/': (_) => const AuthGate(),
        '/login': (_) => const LoginScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/home': (_) => const HomeShell(),
        '/courses': (_) => const CourseListScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/my-courses': (_) => const MyCoursesPage(),
        '/enrollment-detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          return EnrollmentDetailScreen(
            enrollmentId: args is String ? args : '',
          );
        },
        '/course-workspace': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          return CourseWorkspaceScreen(courseId: args is String ? args : '');
        },
        '/course-detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          return CourseDetailScreen(courseId: args is String ? args : '');
        },
      },
    );
  }
}

/// Shows the login screen when signed out and the app shell when signed in,
/// so login/logout navigation is fully driven by [AuthProvider] state (1.1, 1.2).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;

    switch (status) {
      case AuthStatus.authenticated:
        return const HomeShell();
      case AuthStatus.unauthenticated:
      case AuthStatus.authenticating:
      case AuthStatus.submitting:
        return const LoginScreen();
    }
  }
}
