import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'data/mock/mock_lesson_repository.dart';
import 'data/repositories/lesson_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/lesson_provider.dart';
import 'ui/screens/auth/forgot_password_screen.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/auth/profile_screen.dart';
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
    Widget app = MaterialApp(
      title: 'MicroLearn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
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

    bool hasLessonProvider = false;
    try {
      Provider.of<LessonProvider>(context, listen: false);
      hasLessonProvider = true;
    } catch (_) {
      hasLessonProvider = false;
    }

    if (!hasLessonProvider) {
      app = MultiProvider(
        providers: [
          Provider<LessonRepository>(create: (_) => MockLessonRepository()),
          ChangeNotifierProvider<LessonProvider>(
            create: (ctx) => LessonProvider(repo: MockLessonRepository()),
          ),
        ],
        child: app,
      );
    }

    return app;
  }
}

/// Shows the login screen when signed out and the app shell when signed in.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isAuthenticated) {
      return const HomeShell();
    }
    return const LoginScreen();
  }
}
