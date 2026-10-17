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
import 'package:mobile_e_learning_micro_course_system/models/announcement.dart';
import 'package:mobile_e_learning_micro_course_system/models/course_category.dart';
import 'package:mobile_e_learning_micro_course_system/providers/auth_provider.dart';
import 'package:mobile_e_learning_micro_course_system/providers/course_provider.dart';
import 'package:mobile_e_learning_micro_course_system/providers/enrollment_provider.dart';
import 'package:mobile_e_learning_micro_course_system/providers/lesson_provider.dart';
import 'package:provider/provider.dart';

import 'support/student_overview_providers.dart';

const _suspendedNotice =
    'Your account has been suspended. Please contact your teacher or an administrator to have it reactivated.';

/// The server can suspend this session mid-test, with its notice.
class _SuspendableAuthRepository extends MockAuthRepository {
  bool suspended = false;

  @override
  Future<SessionCheck> checkSession() async => suspended
      ? const SessionCheck(valid: false, message: _suspendedNotice)
      : const SessionCheck(valid: true);
}

/// Live sync: account suspension, enrollment changes and enrollment notices
/// made on the web portal reach the open app.
void main() {
  late _SuspendableAuthRepository authRepository;

  setUp(() {
    MockData.reset();
    authRepository = _SuspendableAuthRepository();
  });

  Widget appUnderTest() => MultiProvider(
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

  Future<void> logIn(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(appUnderTest());
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Gmail address'), AppConstants.demoEmail);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), AppConstants.demoPassword);
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();
  }

  Future<void> waitForLiveSync(WidgetTester tester) async {
    await tester.pump(AppConstants.autoRefreshInterval);
    await tester.pumpAndSettle();
  }

  Map<String, dynamic> seededEnrollment(String courseId) =>
      MockData.enrollmentJson.firstWhere((e) => e['courseId'] == courseId);

  testWidgets('a suspended student is signed out and told why', (tester) async {
    await logIn(tester);
    expect(find.text('MicroLearn'), findsOneWidget);

    authRepository.suspended = true;
    await waitForLiveSync(tester);

    expect(find.widgetWithText(FilledButton, 'Log in'), findsOneWidget);
    expect(find.text(_suspendedNotice), findsOneWidget);
  });

  testWidgets('a cancelled enrollment closes the course without a manual refresh',
      (tester) async {
    await logIn(tester);
    await openTab(tester, 'Courses');
    await tester.tap(find.descendant(of: find.byType(Card), matching: find.text('Intro to Flutter')));
    await tester.pumpAndSettle();
    expect(find.text('Continue learning'), findsOneWidget);

    // A teacher cancels the enrollment on the web portal.
    seededEnrollment('course-001')['status'] = 'cancelled';
    await waitForLiveSync(tester);

    expect(find.text('Continue learning'), findsNothing);
    expect(find.textContaining('Your enrollment is cancelled'), findsOneWidget);
  });

  testWidgets('a deleted enrollment is reflected in the open course workspace',
      (tester) async {
    await logIn(tester);
    await openTab(tester, 'My Courses');
    await tester.tap(find.text('Intro to Flutter').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue learning'));
    await tester.pumpAndSettle();
    expect(find.text('You are enrolled in this course'), findsOneWidget);

    // A teacher deletes the enrollment record on the web portal.
    MockData.enrollmentJson.remove(seededEnrollment('course-001'));
    await waitForLiveSync(tester);

    expect(find.text('You are no longer enrolled — enroll again from the catalog'), findsOneWidget);
    expect(find.textContaining('Continue Learning:'), findsNothing);
  });

  testWidgets('a new enrollment notice pops up and is listed', (tester) async {
    await logIn(tester);
    await waitForLiveSync(tester); // the first check records the notices already shown

    MockData.announcementJson.add({
      'id': 'notice-live',
      'type': 'enrollment',
      'title': 'Enrollment suspended',
      'content': 'Your enrollment in "Intro to Flutter" was suspended.',
      'course': {'id': 'course-001', 'title': 'Intro to Flutter'},
      'published_at': '2026-10-17T09:00:00.000Z',
    });
    addTearDown(() => MockData.announcementJson.removeWhere((a) => a['id'] == 'notice-live'));

    await waitForLiveSync(tester);

    expect(find.textContaining('Enrollment suspended: Your enrollment'), findsOneWidget);
  });

  group('models', () {
    test('a personal notice from GET /notifications parses as an enrollment notice', () {
      final notice = Announcement.fromJson({
        'id': 'notice-9b2',
        'type': 'enrollment',
        'title': 'Enrollment removed',
        'content': 'Your enrollment record was deleted.',
        'course_id': 7,
        'course': {'id': 7, 'title': 'Python'},
        'user': {'name': 'Teacher'},
        'published_at': '2026-10-17T08:00:00Z',
      });
      expect(notice.isEnrollmentNotice, isTrue);
      expect(notice.typeLabel, 'My enrollment');
      expect(notice.courseTitle, 'Python');
      expect(notice.authorName, 'Teacher');
    });

    test('categories without published courses are hidden from the catalog chips', () {
      final provider = CourseProvider(repo: MockCourseRepository())
        ..categories = [
          CourseCategory.fromJson({'id': 1, 'name': 'Web', 'courses_count': 2, 'description': 'HTML and CSS'}),
          CourseCategory.fromJson({'id': 2, 'name': 'Empty', 'courses_count': 0, 'description': ' '}),
        ];
      expect(provider.browsableCategories.map((c) => c.name), ['Web']);
      expect(provider.categories.first.description, 'HTML and CSS');
      expect(provider.categories.last.description, isNull);
      expect(provider.categoryNameOf(''), 'Uncategorized');
    });
  });
}
