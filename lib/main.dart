import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/mock/mock_auth_repository.dart';
import 'data/mock/mock_course_repository.dart';
import 'data/mock/mock_enrollment_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/course_repository.dart';
import 'data/repositories/enrollment_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/course_provider.dart';
import 'providers/enrollment_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        // Repository wiring — the single place to flip Mock -> Rest when the
        // API exists (AGENT.md §5).
        Provider<AuthRepository>(create: (_) => MockAuthRepository()),
        Provider<CourseRepository>(create: (_) => MockCourseRepository()),
        Provider<EnrollmentRepository>(
          create: (_) => MockEnrollmentRepository(),
        ),
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
      ],
      child: const MicroLearnApp(),
    ),
  );
}
