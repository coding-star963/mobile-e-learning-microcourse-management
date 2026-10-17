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
import 'package:mobile_e_learning_micro_course_system/providers/auth_provider.dart';
import 'package:mobile_e_learning_micro_course_system/providers/course_provider.dart';
import 'package:mobile_e_learning_micro_course_system/providers/enrollment_provider.dart';
import 'package:mobile_e_learning_micro_course_system/providers/lesson_provider.dart';
import 'package:provider/provider.dart';

import 'support/student_overview_providers.dart';

/// Mock sessions never expire; this one can be "deactivated" mid-test.
class _DeactivatableAuthRepository extends MockAuthRepository {
  bool active = true;

  @override
  Future<bool> isSessionValid() async => active;
}

/// Auto-refresh: changes made on the web portal reach the open app.
void main() {
  late _DeactivatableAuthRepository authRepository;

  Widget appUnderTest() {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: authRepository),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(repo: authRepository),
        ),
        ChangeNotifierProvider<CourseProvider>(
          create: (_) => CourseProvider(repo: MockCourseRepository()),
        ),
        ChangeNotifierProvider<EnrollmentProvider>(
          create: (_) => EnrollmentProvider(repo: MockEnrollmentRepository()),
        ),
        ChangeNotifierProvider<LessonProvider>(
          create: (_) => LessonProvider(repo: MockLessonRepository()),
        ),
        ...studentOverviewProviders(),
      ],
      child: const MicroLearnApp(),
    );
  }

  Future<void> logIn(WidgetTester tester) async {
    await tester.pumpWidget(appUnderTest());
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Gmail address'), AppConstants.demoEmail);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), AppConstants.demoPassword);
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();
  }

  Future<void> waitForAutoRefresh(WidgetTester tester) async {
    await tester.pump(AppConstants.autoRefreshInterval);
    await tester.pumpAndSettle();
  }

  setUp(() => authRepository = _DeactivatableAuthRepository());

  testWidgets('a newly published announcement appears without a manual refresh',
      (tester) async {
    const title = 'Posted from the web portal';
    await logIn(tester);
    await openTab(tester, 'Updates');
    expect(find.text(title), findsNothing);

    // A teacher publishes on the web while the student has the app open.
    MockData.announcementJson.add({
      'id': 'announcement-live',
      'title': title,
      'content': 'Published while the student had the app open.',
      'type': 'important',
      'course_id': null,
      'courseTitle': null,
      'authorName': 'Admin User',
      'published_at': '2026-10-01T09:00:00.000Z',
    });
    addTearDown(() => MockData.announcementJson
        .removeWhere((a) => a['id'] == 'announcement-live'));

    await waitForAutoRefresh(tester);

    expect(find.text(title), findsWidgets);
  });

  testWidgets('a deactivated student is returned to the login screen',
      (tester) async {
    await logIn(tester);
    expect(find.text('MicroLearn'), findsOneWidget);

    authRepository.active = false;
    await waitForAutoRefresh(tester);

    expect(find.widgetWithText(FilledButton, 'Log in'), findsOneWidget);
    expect(find.textContaining('deactivated'), findsOneWidget);
  });
}
