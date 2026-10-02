// ALL mock seed data lives in this single file (AGENT.md §6). No other file
// may hard-code sample content. Seed data is written as JSON maps and parsed
// via `Model.fromJson` so the future REST API returns the same shape.
//
// Module 1 currently consumes the user + credential seeds. Later modules will
// append their own seeds here (courses, lessons, enrollments, ...).
import '../../core/constants.dart';
import '../../models/announcement.dart';
import '../../models/course.dart';
import '../../models/course_category.dart';
import '../../models/enrollment.dart';
import '../../models/lesson.dart';
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
    notificationsSeenAt.clear();
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

  // ===========================================================================
  // Module 4 — Lesson & Learning Content seeds (4.1–4.6)
  // ===========================================================================

  static final List<Map<String, dynamic>> lessonJson = [
    {
      'id': 'lesson-001',
      'course_id': 'course-001',
      'title': '1. Welcome to Flutter Architecture',
      'description':
          'Get an executive breakdown of the Flutter framework: widgets, element tree, render objects, and the reactive state loop.',
      'status': 'published',
      'availability': 'free',
      'order': 1,
      'video_url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      'audio_url': null,
      'duration_seconds': 480,
      'duration_formatted': '8 min',
      'is_free_preview': true,
      'resources': [
        {
          'id': 'res-001',
          'name': 'Flutter-CheatSheet-v3.pdf',
          'file_url': 'https://example.com/flutter-cheatsheet.pdf',
          'file_type': 'pdf',
          'file_size': 2450000,
          'order': 1,
        },
        {
          'id': 'res-002',
          'name': 'Starter-Code-Project.zip',
          'file_url': 'https://example.com/starter.zip',
          'file_type': 'zip',
          'file_size': 5120000,
          'order': 2,
        },
      ],
    },
    {
      'id': 'lesson-002',
      'course_id': 'course-001',
      'title': '2. High-Performance Widgets & Layouts',
      'description':
          'Learn to craft breathtaking user interfaces with zero jank using Flex, Stack, and CustomMultiChildLayout widgets.',
      'status': 'published',
      'availability': 'free',
      'order': 2,
      'video_url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
      'audio_url': 'https://example.com/audio/lesson2.mp3',
      'duration_seconds': 720,
      'duration_formatted': '12 min',
      'is_free_preview': false,
      'resources': [
        {
          'id': 'res-003',
          'name': 'Layout-Architecture-Guide.pdf',
          'file_url': 'https://example.com/layout-guide.pdf',
          'file_type': 'pdf',
          'file_size': 3100000,
          'order': 1,
        },
      ],
    },
    {
      'id': 'lesson-003',
      'course_id': 'course-002',
      'title': '1. Dart Concurrency: Isolates & Message Passing',
      'description':
          'Master true parallelism in Dart. Offload heavy computation from the UI thread using isolate spawning and ports.',
      'status': 'published',
      'availability': 'free',
      'order': 1,
      'video_url': null,
      'audio_url': 'https://example.com/audio/isolates.mp3',
      'duration_seconds': 900,
      'duration_formatted': '15 min',
      'is_free_preview': true,
      'resources': [
        {
          'id': 'res-004',
          'name': 'Isolates-Deep-Dive.pdf',
          'file_url': 'https://example.com/isolates.pdf',
          'file_type': 'pdf',
          'file_size': 1800000,
          'order': 1,
        },
      ],
    },
    {
      'id': 'lesson-004',
      'course_id': 'course-003',
      'title': '1. Semantic HTML & Accessible Structure',
      'description':
          'Structure web applications for maximum accessibility, search engine indexing, and screen reader compatibility.',
      'status': 'published',
      'availability': 'free',
      'order': 1,
      'video_url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      'audio_url': null,
      'duration_seconds': 540,
      'duration_formatted': '9 min',
      'is_free_preview': true,
      'resources': [],
    },
    {
      'id': 'lesson-005',
      'course_id': 'course-003',
      'title': '2. Modern CSS & Grid Mastery',
      'description':
          'Build responsive, responsive 2D layouts using CSS Grid and subgrid without unnecessary container divs.',
      'status': 'published',
      'availability': 'free',
      'order': 2,
      'video_url': null,
      'audio_url': null,
      'duration_seconds': 600,
      'duration_formatted': '10 min',
      'is_free_preview': false,
      'resources': [
        {
          'id': 'res-005',
          'name': 'CSS-Grid-Blueprint.pdf',
          'file_url': 'https://example.com/grid.pdf',
          'file_type': 'pdf',
          'file_size': 1200000,
          'order': 1,
        },
      ],
    },
    {
      'id': 'lesson-006',
      'course_id': 'course-003',
      'title': '3. Responsive Typography & Media Queries',
      'description':
          'Create fluid layouts that adapt smoothly from smartphones to 4K desktop displays using clamp() and container queries.',
      'status': 'published',
      'availability': 'locked',
      'order': 3,
      'video_url': null,
      'audio_url': null,
      'duration_seconds': 800,
      'duration_formatted': '13 min',
      'is_free_preview': false,
      'resources': [],
    },
    {
      'id': 'lesson-007',
      'course_id': 'course-004',
      'title': '1. The Visual Hierarchy of Data',
      'description':
          'Design dashboards that communicate insights in seconds. Apply visual weights, color psychology, and gestalt principles.',
      'status': 'published',
      'availability': 'free',
      'order': 1,
      'video_url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
      'audio_url': null,
      'duration_seconds': 660,
      'duration_formatted': '11 min',
      'is_free_preview': true,
      'resources': [],
    },
    {
      'id': 'lesson-008',
      'course_id': 'course-005',
      'title': '1. Qualitative User Interview Fundamentals',
      'description':
          'Discover unstated user pain points without asking leading questions. Master active listening and script crafting.',
      'status': 'published',
      'availability': 'free',
      'order': 1,
      'video_url': null,
      'audio_url': 'https://example.com/audio/ux-interviews.mp3',
      'duration_seconds': 450,
      'duration_formatted': '7 min',
      'is_free_preview': true,
      'resources': [],
    },
    {
      'id': 'lesson-009',
      'course_id': 'course-005',
      'title': '2. Usability Testing & Synthesis',
      'description':
          'Record behavioral friction, map heatmaps, and translate observed obstacles into ranked product improvements.',
      'status': 'published',
      'availability': 'locked',
      'order': 2,
      'video_url': null,
      'audio_url': null,
      'duration_seconds': 580,
      'duration_formatted': '9 min',
      'is_free_preview': false,
      'resources': [],
    },
    {
      'id': 'lesson-010',
      'course_id': 'course-006',
      'title': '1. Microservices & Cold Starts',
      'description': 'Under preparation for upcoming release.',
      'status': 'draft',
      'availability': 'locked',
      'order': 1,
      'video_url': null,
      'audio_url': null,
      'duration_seconds': 300,
      'duration_formatted': '5 min',
      'is_free_preview': false,
      'resources': [],
    },
  ];

  /// Fresh [Lesson] copies for a course, sorted by order (4.1, 4.5).
  static List<Lesson> lessonsForCourse(String courseId) {
    final list = lessonJson
        .where((l) => l['course_id'] == courseId)
        .map(Lesson.fromJson)
        .toList();
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  /// Fresh [Lesson] copy for a single lesson id (4.2).
  static Lesson? lessonById(String lessonId) {
    final match = lessonJson.firstWhere(
      (l) => l['id'] == lessonId,
      orElse: () => const {},
    );
    if (match.isEmpty) return null;
    return Lesson.fromJson(match);
  }

  // ===========================================================================
  // Module 6 — Announcements & Notifications seeds (6.1–6.4)
  // ===========================================================================

  /// Published announcements visible to the demo student: general ones and
  /// ones for enrolled courses (course-001, course-003, course-004).
  static final List<Map<String, dynamic>> announcementJson = [
    {
      'id': 'announcement-001',
      'title': 'Welcome to the new semester',
      'content': 'Browse the catalog and enroll in the micro-courses for your section.',
      'type': 'general',
      'course_id': null,
      'courseTitle': null,
      'authorName': 'Admin User',
      'published_at': '2026-09-01T08:00:00.000Z',
    },
    {
      'id': 'announcement-002',
      'title': 'New lesson: High-Performance Widgets & Layouts',
      'content': 'A new lesson is now available in Intro to Flutter.',
      'type': 'course_update',
      'course_id': 'course-001',
      'courseTitle': 'Intro to Flutter',
      'authorName': 'Sarah Johnson',
      'published_at': '2026-09-20T10:30:00.000Z',
    },
    {
      'id': 'announcement-003',
      'title': 'Quiz schedule moved',
      'content': 'The HTML & CSS quiz moves to Friday. Review lessons 1 to 3.',
      'type': 'important',
      'course_id': 'course-003',
      'courseTitle': 'HTML & CSS Basics',
      'authorName': 'Sarah Johnson',
      'published_at': '2026-09-25T13:00:00.000Z',
    },
  ];

  static List<Announcement> get announcements =>
      announcementJson.map(Announcement.fromJson).toList();

  /// When each student last opened their notifications (6.3).
  static final Map<String, DateTime> notificationsSeenAt = {};
}
