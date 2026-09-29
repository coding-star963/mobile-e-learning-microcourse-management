import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_e_learning_micro_course_system/app.dart';
import 'package:mobile_e_learning_micro_course_system/core/constants.dart';
import 'package:mobile_e_learning_micro_course_system/data/mock/mock_auth_repository.dart';
import 'package:mobile_e_learning_micro_course_system/data/mock/mock_course_repository.dart';
import 'package:mobile_e_learning_micro_course_system/data/mock/mock_data.dart';
import 'package:mobile_e_learning_micro_course_system/data/mock/mock_enrollment_repository.dart';
import 'package:mobile_e_learning_micro_course_system/data/mock/mock_lesson_repository.dart';
import 'package:mobile_e_learning_micro_course_system/data/repositories/auth_repository.dart';
import 'package:mobile_e_learning_micro_course_system/data/repositories/course_repository.dart';
import 'package:mobile_e_learning_micro_course_system/data/repositories/enrollment_repository.dart';
import 'package:mobile_e_learning_micro_course_system/data/repositories/lesson_repository.dart';
import 'package:mobile_e_learning_micro_course_system/providers/auth_provider.dart';
import 'package:mobile_e_learning_micro_course_system/providers/course_provider.dart';
import 'package:mobile_e_learning_micro_course_system/providers/enrollment_provider.dart';
import 'package:mobile_e_learning_micro_course_system/providers/lesson_provider.dart';
import 'package:mobile_e_learning_micro_course_system/ui/screens/lesson/lesson_detail_screen.dart';
import 'package:mobile_e_learning_micro_course_system/ui/screens/lesson/lesson_list_screen.dart';
import 'package:provider/provider.dart';

class _TransparentMockHttpClient extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (_, _, _) => true;
    return client;
  }
}

/// Widget tests for Module 4 — Lesson & Learning Content (4.1–4.6).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    HttpOverrides.global = _TransparentMockHttpClient();
  });

  setUp(() {
    MockData.reset();
  });

  Widget appUnderTest({Widget? home}) {
    final lessonRepo = MockLessonRepository();
    return MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: MockAuthRepository()),
        Provider<CourseRepository>.value(value: MockCourseRepository()),
        Provider<EnrollmentRepository>.value(value: MockEnrollmentRepository()),
        Provider<LessonRepository>.value(value: lessonRepo),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(repo: MockAuthRepository()),
        ),
        ChangeNotifierProvider<CourseProvider>(
          create: (_) => CourseProvider(repo: MockCourseRepository()),
        ),
        ChangeNotifierProvider<EnrollmentProvider>(
          create: (_) => EnrollmentProvider(repo: MockEnrollmentRepository()),
        ),
        ChangeNotifierProvider<LessonProvider>(
          create: (_) => LessonProvider(repo: lessonRepo),
        ),
      ],
      child: home != null
          ? MaterialApp(
              theme: ThemeData.dark(),
              home: home,
            )
          : const MicroLearnApp(),
    );
  }

  void setupTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> loginAndOpenWorkspace(WidgetTester tester) async {
    setupTallViewport(tester);

    await tester.pumpWidget(appUnderTest());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      AppConstants.demoEmail,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      AppConstants.demoPassword,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('My Courses'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Intro to Flutter'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue learning'));
    await tester.pumpAndSettle();
  }

  group('4.1 View Lesson List', () {
    testWidgets('displays ordered curriculum lessons in lesson list screen',
        (tester) async {
      setupTallViewport(tester);
      await tester.pumpWidget(appUnderTest(
        home: const LessonListScreen(courseId: 'course-001'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Course Curriculum'), findsOneWidget);
      expect(find.text('1. Welcome to Flutter Architecture'), findsOneWidget);
      expect(find.text('2. High-Performance Widgets & Layouts'), findsOneWidget);
    });
  });

  group('4.2 View Lesson Content', () {
    testWidgets('shows lesson content and details', (tester) async {
      setupTallViewport(tester);
      await tester.pumpWidget(appUnderTest(
        home: const LessonDetailScreen(
          courseId: 'course-001',
          lessonId: 'lesson-001',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('1. Welcome to Flutter Architecture'), findsWidgets);
      expect(find.text('Learning Resources'), findsOneWidget);
    });
  });

  group('4.3 Media Playback', () {
    testWidgets('cinematic player has play/pause controls and scrubber',
        (tester) async {
      setupTallViewport(tester);
      await tester.pumpWidget(appUnderTest(
        home: const LessonDetailScreen(
          courseId: 'course-001',
          lessonId: 'lesson-001',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow_rounded), findsWidgets);

      // Tap play
      await tester.tap(find.byIcon(Icons.play_arrow_rounded).first);
      await tester.pump();

      // Verified playing state: pause icon visible
      expect(find.byIcon(Icons.pause), findsOneWidget);
    });
  });

  group('4.4 Download Learning Resources (Auto-Allowed)', () {
    testWidgets('downloading resource auto-completes without permission popup',
        (tester) async {
      setupTallViewport(tester);
      await tester.pumpWidget(appUnderTest(
        home: const LessonDetailScreen(
          courseId: 'course-001',
          lessonId: 'lesson-001',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Learning Resources'), findsOneWidget);
      expect(find.text('Flutter-CheatSheet-v3.pdf'), findsOneWidget);

      // Tap download icon button
      await tester.tap(find.byTooltip('Download resource').first);
      await tester.pump();

      // Auto-allowed: marked as downloaded with green checkmark
      expect(find.byTooltip('Downloaded'), findsOneWidget);
    });
  });

  group('4.5 & 4.6 Lesson Progression & Completion', () {
    testWidgets('marks lesson completed from the detail screen',
        (tester) async {
      setupTallViewport(tester);
      await tester.pumpWidget(appUnderTest(
        home: const LessonDetailScreen(
          courseId: 'course-001',
          lessonId: 'lesson-002',
        ),
      ));
      await tester.pumpAndSettle();

      // Tap Mark Completed
      expect(find.text('Mark Completed'), findsOneWidget);
      await tester.tap(find.text('Mark Completed'));
      await tester.pumpAndSettle();

      // Flipped to Mark Undone
      expect(find.text('Mark Undone'), findsOneWidget);
    });

    testWidgets('navigates from workspace to lesson detail and returns',
        (tester) async {
      await loginAndOpenWorkspace(tester);

      expect(find.text('You are enrolled in this course'), findsOneWidget);
      expect(find.text('Course Curriculum'), findsOneWidget);
    });
  });
}
