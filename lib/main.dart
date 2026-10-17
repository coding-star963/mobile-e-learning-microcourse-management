import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/api/rest_announcement_repository.dart';
import 'data/api/rest_auth_repository.dart';
import 'data/api/rest_course_repository.dart';
import 'data/api/rest_dashboard_repository.dart';
import 'data/api/rest_enrollment_repository.dart';
import 'data/api/rest_lesson_repository.dart';
import 'data/api/rest_progress_repository.dart';
import 'data/repositories/announcement_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/course_repository.dart';
import 'data/repositories/dashboard_repository.dart';
import 'data/repositories/enrollment_repository.dart';
import 'data/repositories/lesson_repository.dart';
import 'data/repositories/progress_repository.dart';
import 'providers/announcement_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/course_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/enrollment_provider.dart';
import 'providers/lesson_provider.dart';
import 'providers/progress_provider.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        // Real REST API repositories connected to Laravel backend
        // with offline resilience / mock fallback
        Provider<AuthRepository>(create: (_) => RestAuthRepository()),
        Provider<CourseRepository>(create: (_) => RestCourseRepository()),
        Provider<EnrollmentRepository>(create: (_) => RestEnrollmentRepository()),
        Provider<LessonRepository>(create: (_) => RestLessonRepository()),
        Provider<AnnouncementRepository>(create: (_) => RestAnnouncementRepository()),
        Provider<DashboardRepository>(create: (_) => RestDashboardRepository()),
        Provider<ProgressRepository>(create: (_) => RestProgressRepository()),

        ChangeNotifierProvider(
          // 1.1 Resume the saved login, if any, when the app starts.
          create: (context) => AuthProvider(
            repo: context.read<AuthRepository>(),
          )..restoreSession(),
        ),
        ChangeNotifierProvider(
          create: (context) => CourseProvider(
            repo: context.read<CourseRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => EnrollmentProvider(
            repo: context.read<EnrollmentRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => LessonProvider(
            repo: context.read<LessonRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => AnnouncementProvider(
            repo: context.read<AnnouncementRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => DashboardProvider(
            repo: context.read<DashboardRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ProgressProvider(
            repo: context.read<ProgressRepository>(),
          ),
        ),
        // Light / dark mode, remembered on this device.
        ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
      ],
      child: const MicroLearnApp(),
    ),
  );
}
