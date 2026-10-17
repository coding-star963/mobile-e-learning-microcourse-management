import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'ui/screens/auth/forgot_password_screen.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/auth/profile_screen.dart';
import 'ui/screens/auth/register_screen.dart';
import 'ui/screens/course/course_detail_screen.dart';
import 'ui/screens/course/course_list_screen.dart';
import 'ui/screens/dashboard/home_shell.dart';
import 'ui/screens/enrollment/course_workspace_screen.dart';
import 'ui/screens/enrollment/enrollment_detail_screen.dart';
import 'ui/screens/enrollment/my_courses_screen.dart';
import 'ui/screens/lesson/lesson_detail_screen.dart';
import 'ui/screens/lesson/lesson_list_screen.dart';

/// Root widget: MaterialApp, luxury theme, and named routes.
class MicroLearnApp extends StatelessWidget {
  const MicroLearnApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Optional so tests can build the app without it (then: dark, the original look).
    final themeMode = context.watch<ThemeProvider?>()?.mode ?? ThemeMode.dark;

    return MaterialApp(
      title: 'MicroLearn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      // Switch instantly so the app's own colors and Material's stay in step.
      themeAnimationDuration: Duration.zero,
      builder: (context, child) => _PaletteSync(
        brightness: Theme.of(context).brightness,
        child: child ?? const SizedBox.shrink(),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const AuthGate(),
        '/login': (_) => const LoginScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/register': (_) => const RegisterScreen(),
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
        '/lessons': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          return LessonListScreen(courseId: args is String ? args : '');
        },
        '/lesson-detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is Map) {
            return LessonDetailScreen(
              courseId: args['courseId']?.toString() ?? '',
              lessonId: args['lessonId']?.toString() ?? '',
            );
          }
          return const LessonDetailScreen(courseId: '', lessonId: '');
        },
      },
    );
  }
}

/// Keeps [AppTheme]'s light/dark colors in step with the active theme.
///
/// Screens read those colors directly (not through Theme.of), so when the
/// brightness changes every screen below is rebuilt in place; state such as
/// the open page, tab and scroll position is kept.
class _PaletteSync extends StatefulWidget {
  const _PaletteSync({required this.brightness, required this.child});

  final Brightness brightness;
  final Widget child;

  @override
  State<_PaletteSync> createState() => _PaletteSyncState();
}

class _PaletteSyncState extends State<_PaletteSync> {
  @override
  void didUpdateWidget(_PaletteSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.brightness != widget.brightness) {
      AppTheme.brightness = widget.brightness;
      void rebuild(Element element) {
        element.markNeedsBuild();
        element.visitChildren(rebuild);
      }
      (context as Element).visitChildren(rebuild);
    }
  }

  @override
  Widget build(BuildContext context) {
    AppTheme.brightness = widget.brightness;
    return widget.child;
  }
}

/// Shows the login screen when signed out and the app shell when signed in.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isRestoring) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.goldPrimary),
        ),
      );
    }
    if (auth.isAuthenticated) {
      return const HomeShell();
    }
    return const LoginScreen();
  }
}
