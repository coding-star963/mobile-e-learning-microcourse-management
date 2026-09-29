import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/api/rest_auth_repository.dart';
import 'data/api/rest_course_repository.dart';
import 'data/api/rest_enrollment_repository.dart';
import 'data/api/rest_lesson_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/course_repository.dart';
import 'data/repositories/enrollment_repository.dart';
import 'data/repositories/lesson_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/course_provider.dart';
import 'providers/enrollment_provider.dart';
import 'providers/lesson_provider.dart';

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

        ChangeNotifierProvider(
          create: (context) => AuthProvider(
            repo: context.read<AuthRepository>(),
          ),
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
      ],
      child: const MicroLearnApp(),
    ),
  );
}
