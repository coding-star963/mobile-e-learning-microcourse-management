// ALL mock seed data lives in this single file (AGENT.md §6). No other file
// may hard-code sample content. Seed data is written as JSON maps and parsed
// via `Model.fromJson` so the future REST API returns the same shape.
//
// Module 1 currently consumes the user + credential seeds. Later modules will
// append their own seeds here (courses, lessons, enrollments, ...).
import '../../core/constants.dart';
import '../../models/course.dart';
import '../../models/course_category.dart';
import '../../models/enrollment.dart';
import '../../models/user.dart';

class MockData {
  const MockData._();

  // -- Mutable in-memory state (resets on app restart, AGENT.md §6) ---------

  /// Registered demo student accounts with their passwords.
  /// Keys: email -> {'user': AppUser JSON, 'password': String}
  static final Map<String, Map<String, dynamic>> accountJsonByName = {
    AppConstants.demoEmail: {
      'user': {
        'id': 'student-001',
        'fullName': 'Alex Rivera',
        'email': AppConstants.demoEmail,
        'photoUrl': null,
      },
      'password': AppConstants.demoPassword,
    },
  };

  /// Profile updates applied during the session (1.4), stored per user id.
  static final Map<String, Map<String, dynamic>> profileOverrides = {};

  /// Emails for which a password reset has been requested (1.3).
  static final List<String> passwordResetRequests = [];

  // -- Typed accessors (parsed through Model.fromJson) -----------------------

  /// Deep-copies the JSON then applies any in-session profile overrides
  /// so the base seed is never mutated.
  static Map<String, dynamic> _accountJsonFor(String email) {
    final account = accountJsonByName[email.toLowerCase().trim()];
    if (account == null) return const {};
    final userJson = Map<String, dynamic>.from(account['user'] as Map);
    final overrides = profileOverrides[userJson['id'] as String];
    if (overrides != null) userJson.addAll(overrides);
    return userJson;
  }

  /// Returns a fresh [AppUser] copy from seed + overrides.
  static AppUser userFor(String email) =>
      AppUser.fromJson(_accountJsonFor(email));

  static bool accountExists(String email) =>
      accountJsonByName.containsKey(email.toLowerCase().trim());

  // -- Module 2 typed accessors ----------------------------------------------

  /// Fresh [CourseCategory] copies parsed through `Model.fromJson`.
  static List<CourseCategory> get categories =>
      categoryJson.map(CourseCategory.fromJson).toList();

  /// Fresh [Course] copies parsed through `Model.fromJson`.
  static List<Course> get courses => courseJson.map(Course.fromJson).toList();

  // ===========================================================================
  // Module 3 — Course Enrollment seeds (3.1–3.4)
  // ===========================================================================

  /// Enrollments for the demo student with varied progress (0%, partial,
  /// 100%) so progress displays are exercised (AGENT.md §6).
  static List<Map<String, dynamic>> enrollmentSeed() => [
    {
      'id': 'enrollment-001',
      'studentId': AppConstants.demoStudentId,
      'courseId': 'course-001',
      'enrolledAt': '2026-09-01T09:00:00.000Z',
      'completedLessonIds': ['lesson-001'],
      'status': 'active',
    },
    {
      'id': 'enrollment-002',
      'studentId': AppConstants.demoStudentId,
      'courseId': 'course-003',
      'enrolledAt': '2026-09-05T14:30:00.000Z',
      'completedLessonIds': <String>[],
      'status': 'active',
    },
    {
      'id': 'enrollment-003',
      'studentId': AppConstants.demoStudentId,
      'courseId': 'course-004',
      'enrolledAt': '2026-08-20T11:15:00.000Z',
      'completedLessonIds': ['lesson-007'],
      'status': 'completed',
    },
  ];

  /// Mutable in-memory enrollment store.
  static final List<Map<String, dynamic>> enrollmentJson = enrollmentSeed();

  /// Restores ALL mutable state to seed values — simulates an app restart
  /// (AGENT.md §6 "in-memory means in-memory"). Used by tests for isolation.
  static void reset() {
    enrollmentJson
      ..clear()
      ..addAll(enrollmentSeed());
    profileOverrides.clear();
    passwordResetRequests.clear();
  }

  /// Fresh [Enrollment] copies for one student, parsed through `fromJson`.
  static List<Enrollment> enrollmentsFor(String studentId) => enrollmentJson
      .where((e) => e['studentId'] == studentId)
      .map(Enrollment.fromJson)
      .toList();

  // ===========================================================================
  // Module 2 — Course Discovery & Browsing seeds (2.1–2.5)
  // ===========================================================================

  /// Course categories (2.3).
  static final List<Map<String, dynamic>> categoryJson = [
    {'id': 'cat-mobile-dev', 'name': 'Mobile Development'},
    {'id': 'cat-web-dev', 'name': 'Web Development'},
    {'id': 'cat-data', 'name': 'Data & Analytics'},
    {'id': 'cat-design', 'name': 'UX & Design'},
  ];

  /// Courses (2.1–2.5). Includes published AND unpublished courses so the
  /// catalog filter and status badges can be exercised.
  static final List<Map<String, dynamic>> courseJson = [
    {
      'id': 'course-001',
      'title': 'Intro to Flutter',
      'description':
          'Build your first cross-platform mobile app with Flutter. Learn '
          'widgets, layout, and navigation by shipping a small app.',
      'categoryId': 'cat-mobile-dev',
      'objectives': [
        'Install the Flutter SDK and tooling',
        'Compose layouts with widgets',
        'Navigate between screens',
      ],
      'difficultyLevel': 'beginner',
      'thumbnailUrl': 'https://picsum.photos/seed/flutter/640/360',
      'isPublished': true,
      'lessonIds': ['lesson-001', 'lesson-002'],
      'keywords': ['flutter', 'dart', 'mobile', 'app'],
    },
    {
      'id': 'course-002',
      'title': 'Advanced Dart Patterns',
      'description':
          'Level up your Dart with streams, isolates, and idiomatic patterns '
          'used in production Flutter codebases.',
      'categoryId': 'cat-mobile-dev',
      'objectives': [
        'Model async work with streams',
        'Run background tasks with isolates',
        'Apply common design patterns in Dart',
      ],
      'difficultyLevel': 'advanced',
      'thumbnailUrl': 'https://picsum.photos/seed/dart/640/360',
      'isPublished': true,
      'lessonIds': ['lesson-003'],
      'keywords': ['dart', 'patterns', 'async'],
    },
    {
      'id': 'course-003',
      'title': 'HTML & CSS Basics',
      'description':
          'Start building for the web: structure pages with semantic HTML and '
          'style them with modern CSS.',
      'categoryId': 'cat-web-dev',
      'objectives': [
        'Write semantic HTML documents',
        'Style pages with CSS',
        'Publish a simple static page',
      ],
      'difficultyLevel': 'beginner',
      'thumbnailUrl': 'https://picsum.photos/seed/htmlcss/640/360',
      'isPublished': true,
      'lessonIds': ['lesson-004', 'lesson-005', 'lesson-006'],
      'keywords': ['html', 'css', 'web', 'frontend'],
    },
    {
      'id': 'course-004',
      'title': 'Data Visualization Fundamentals',
      'description':
          'Turn raw numbers into clear charts. Covers chart types, color, and '
          'storytelling with data.',
      'categoryId': 'cat-data',
      'objectives': [
        'Choose the right chart for the data',
        'Apply color and layout principles',
        'Build a simple dashboard',
      ],
      'difficultyLevel': 'intermediate',
      'thumbnailUrl': 'https://picsum.photos/seed/dataviz/640/360',
      'isPublished': true,
      'lessonIds': ['lesson-007'],
      'keywords': ['charts', 'data', 'visualization', 'dashboard'],
    },
    {
      'id': 'course-005',
      'title': 'UX Research Crash Course',
      'description':
          'Plan and run lightweight user research: interviews, usability '
          'tests, and turning findings into design decisions.',
      'categoryId': 'cat-design',
      'objectives': [
        'Run a 5-user usability test',
        'Write actionable research questions',
        'Synthesize findings into decisions',
      ],
      'difficultyLevel': 'intermediate',
      'thumbnailUrl': 'https://picsum.photos/seed/ux/640/360',
      'isPublished': true,
      'lessonIds': ['lesson-008', 'lesson-009'],
      'keywords': ['ux', 'research', 'usability', 'design'],
    },
    {
      'id': 'course-006',
      'title': 'Serverless APIs with Node (Draft)',
      'description':
          'Design and deploy small serverless APIs. This course is still '
          'being prepared and is not open for enrollment yet.',
      'categoryId': 'cat-web-dev',
      'objectives': [
        'Design REST endpoints',
        'Deploy a serverless function',
      ],
      'difficultyLevel': 'intermediate',
      'thumbnailUrl': 'https://picsum.photos/seed/node/640/360',
      'isPublished': false,
      'lessonIds': ['lesson-010'],
      'keywords': ['node', 'serverless', 'api', 'backend'],
    },
  ];

}
