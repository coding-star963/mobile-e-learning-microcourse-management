# AGENT.md — E-Learning & Micro-Course Management System (Flutter, Student Side)

> **Read this file completely before writing any code.** It is the operating manual for any AI coding agent (and human developer) working in this repository. It defines the project scope, the required architecture, coding conventions, and the **mock-data-first strategy** that must be followed so the app can be switched to a real REST API later with minimal code changes.

---

## 1. Project Overview

A **Flutter mobile application for students/users** of an E-Learning & Micro-Course Management System. Students use this app to:

- Discover published micro-courses
- Enroll in courses
- Access lessons and learning resources
- Monitor their own learning progress
- Receive course-related announcements and notifications

**Scope boundary (important):** This app is **student-facing only**. Administrative and teacher management functions (creating courses, lessons, grading, publishing announcements) belong to the **web admin/teacher system** and are **out of scope** here. Never build admin/teacher CRUD screens in this app.

**Requirements source of truth:** `E_Learning_Micro_Course_Mobile_User_Functionalities.docx` (root of this repo). When in doubt about a feature, re-read it and match its module numbering.

---

## 2. Tech Stack & Ground Rules

| Concern | Choice |
|---|---|
| Framework | Flutter (Material 3), Dart SDK `^3.12.2` |
| State management | **Provider** (`package:provider`, `ChangeNotifier`) |
| Data (current phase) | **REST API is live** — `lib/data/api/` repositories are wired in `main.dart` and talk to the Laravel backend. `shared_preferences` stores only the token, saved user, server URL and notification "seen" time. |
| Mock data | `lib/data/mock/` stays in-memory and is used by widget tests; keep it in sync with each repository contract. |
| Lints | `package:flutter_lints` via `analysis_options.yaml` — code must pass `flutter analyze` with zero issues |
| Tests | `flutter_test` — widget tests must not depend on network or persistence |

**Non-negotiable architecture rule:** UI code must never read or write mock data directly. All data flows through the layers in §4. This is what makes the future REST API swap painless.

---

## 3. Functional Modules (from the requirements document)

Every feature you implement must reference its module/function ID below. Use these IDs in code comments, commit messages, and test names (e.g. `// Implements 2.2 Search Courses`).

### Module 1 — Authentication & Profile Management
| ID | Function |
|---|---|
| 1.1 | Login — secure access with registered credentials |
| 1.2 | Logout — end session and sign out |
| 1.3 | Password Recovery — request password reset |
| 1.4 | Profile Management — view/update name, email, profile photo, password |

### Module 2 — Course Discovery & Browsing
| ID | Function |
|---|---|
| 2.1 | View Available Courses — browse published micro-courses open for enrollment |
| 2.2 | Search Courses — search by title or keywords |
| 2.3 | Browse by Category — filter courses by assigned category |
| 2.4 | View Course Details — title, description, category, learning objectives, difficulty level, thumbnail, available lessons |
| 2.5 | View Course Status — available for enrollment / learning |

### Module 3 — Course Enrollment
| ID | Function |
|---|---|
| 3.1 | Enroll in Course — enroll in an available micro-course |
| 3.2 | View Enrolled Courses — list of enrolled courses |
| 3.3 | View Enrollment Details — basic info about an enrollment |
| 3.4 | Access Enrolled Course — open and continue learning |

### Module 4 — Lesson & Learning Content
| ID | Function |
|---|---|
| 4.1 | View Course Lessons — lessons included in an enrolled course |
| 4.2 | View Lesson Details — title, description, available learning content |
| 4.3 | Play Video/Audio — access instructional video/audio materials |
| 4.4 | View/Download Learning Resources — PDFs, documents, images |
| 4.5 | Follow Lesson Order — lessons in the teacher-arranged sequence |
| 4.6 | View Lesson Availability — whether a lesson is currently accessible |

### Module 5 — Learning Progress
| ID | Function |
|---|---|
| 5.1 | Track Lesson Completion — mark/record lessons as completed |
| 5.2 | View Course Progress — current progress in an enrolled course |
| 5.3 | View Course Completion Percentage — simple percentage complete |
| 5.4 | View Learning History — past activity and completed courses |
| 5.5 | Continue Learning — return to current progress point |

### Module 6 — Announcements & Notifications
| ID | Function |
|---|---|
| 6.1 | View Announcements — announcements for enrolled courses |
| 6.2 | Receive Course Updates — new lessons, updated materials, course changes |
| 6.3 | View Notifications — course-related notifications |
| 6.4 | View Notification History — previously received announcements/notifications |

### Module 7 — Student Dashboard
| ID | Function |
|---|---|
| 7.1 | Student Dashboard — overview of enrolled courses, progress, recent activity |
| 7.2 | My Courses Summary — summary of enrolled/ongoing courses |
| 7.3 | Progress Summary — basic progress info for enrolled courses |
| 7.4 | Recent Announcements — recent relevant announcements/updates |

---

## 4. Required Architecture (Mock-Data-First)

### 4.1 Layered flow

```
Screens / Widgets            (lib/ui/...)
        │  reads via Provider.watch / context.watch
        ▼
Providers (ChangeNotifier)   (lib/providers/...)
        │  calls repository interfaces ONLY
        ▼
Repository interfaces        (lib/data/repositories/...)
        │  implemented by
        ├──► Mock implementations   (lib/data/mock/...)   ← CURRENT PHASE
        └──► REST implementations   (lib/data/api/...)    ← FUTURE PHASE
```

**Dependency direction is one-way, downward.** A screen never imports from `lib/data/`, and a repository never imports Flutter UI code.

### 4.2 Folder structure

```
lib/
├── main.dart                      # App entry; wires Provider scopes + routes
├── app.dart                       # MaterialApp, theme, named routes
├── core/
│   ├── constants.dart             # App-wide constants
│   └── theme.dart                 # Theme data
├── models/                        # Plain Dart model classes
│   ├── user.dart                  # Student profile (Module 1)
│   ├── course_category.dart       # (2.3)
│   ├── course.dart                # (2.x, 3.x)
│   ├── lesson.dart                # (4.x)
│   ├── learning_resource.dart     # PDFs/docs/images/video/audio (4.3, 4.4)
│   ├── enrollment.dart            # (3.x) links student ↔ course, includes progress
│   ├── announcement.dart          # (6.1, 6.2)
│   └── app_notification.dart      # (6.3, 6.4)
├── data/
│   ├── repositories/              # ABSTRACT interfaces (contracts)
│   │   ├── auth_repository.dart
│   │   ├── course_repository.dart
│   │   ├── enrollment_repository.dart
│   │   ├── lesson_repository.dart
│   │   ├── progress_repository.dart
│   │   ├── announcement_repository.dart
│   │   └── notification_repository.dart
│   ├── mock/                      # CURRENT data source
│   │   ├── mock_data.dart         # ALL seed data lives here (see §6)
│   │   ├── mock_auth_repository.dart
│   │   ├── mock_course_repository.dart
│   │   ├── mock_enrollment_repository.dart
│   │   ├── mock_lesson_repository.dart
│   │   ├── mock_progress_repository.dart
│   │   ├── mock_announcement_repository.dart
│   │   └── mock_notification_repository.dart
│   └── api/                       # FUTURE data source (create only when API exists)
│       └── (rest_*_repository.dart, api_client.dart)
├── providers/
│   ├── auth_provider.dart
│   ├── course_provider.dart
│   ├── enrollment_provider.dart
│   ├── lesson_provider.dart
│   ├── progress_provider.dart
│   ├── announcement_provider.dart
│   ├── notification_provider.dart
│   └── dashboard_provider.dart    # Aggregates data for Module 7
└── ui/
    ├── screens/
    │   ├── auth/                  # login, forgot_password, profile  (Module 1)
    │   ├── course/                # course_list, course_detail, category (Module 2)
    │   ├── enrollment/            # my_courses, enrollment_detail (Module 3)
    │   ├── lesson/                # lesson_list, lesson_detail, video/audio player, resources (Module 4)
    │   ├── progress/              # course_progress, learning_history (Module 5)
    │   ├── notifications/         # announcements, notification list/history (Module 6)
    │   └── dashboard/             # home dashboard (Module 7)
    └── widgets/                   # Shared reusable widgets (course_card, progress_bar, ...)
```

### 4.3 Repository contracts

- Every repository is an **abstract class** in `lib/data/repositories/`.
- Mock classes implement the contract and are named `Mock<Name>Repository`; future REST classes will be `Rest<Name>Repository`.
- Repository methods return **models or `Future<List<Model>>`/`Future<Model?>`**, never widget types, never raw JSON maps.
- Mutations (enroll, mark complete, update profile, login/logout) are also repository methods so the API swap replaces them all.

Example contract style to follow:

```dart
// lib/data/repositories/course_repository.dart
abstract class CourseRepository {
  Future<List<Course>> getPublishedCourses();          // 2.1
  Future<List<Course>> searchCourses(String query);    // 2.2
  Future<List<Course>> getCoursesByCategory(String categoryId); // 2.3
  Future<Course?> getCourseDetails(String courseId);   // 2.4
}
```

```dart
// lib/data/mock/mock_course_repository.dart — filters the seed list in mock_data.dart
class MockCourseRepository implements CourseRepository {
  @override
  Future<List<Course>> getPublishedCourses() async {
    await Future<void>.delayed(const Duration(milliseconds: 300)); // simulate latency
    return MockData.courses.where((c) => c.isPublished).toList();
  }
  // ...
}
```

### 4.4 Wiring via Provider

- `main.dart` registers repositories and providers with `MultiProvider` (or `ProxyProvider` where a provider needs a repository).
- Screens obtain providers with `context.watch<T>()` / `context.read<T>()`; never construct repositories or read `MockData` inside screens.
- One `ChangeNotifier` per module area (see folder structure); the dashboard provider may depend on others via `ProxyProvider`.

---

## 5. REST API Migration Plan (design for it NOW)

The app is currently mock-backed **by design**. When the REST API is ready, the swap must require **no changes to screens or providers** — only:

1. Create `lib/data/api/api_client.dart` (an HTTP wrapper; pick the package then, e.g. `http` or `dio`).
2. Create `lib/data/api/rest_<name>_repository.dart` for each repository contract.
3. In `main.dart`, flip the injected implementation from `Mock...` to `Rest...` (single wiring point — keep it that way).

To guarantee that swap is trivial, follow these rules today:

- **Models must have `fromJson`/`toJson`** from day one, and mock seed data must be written as JSON-compatible maps converted through `Model.fromJson` (see §6). This keeps the exact serialization shape the future API will use.
- Use **`String` IDs** (e.g. `'course-001'`) — most REST APIs expose string/GUID ids.
- Never let providers know whether data came from mock or network — no `isMock` flags leaking upward.
- Keep repository method signatures aligned with expected REST endpoints (table below).

**Expected future endpoint mapping** (align method names now; exact paths to be confirmed when the API spec exists):

| Repository method (existing contract) | Likely REST endpoint |
|---|---|
| `AuthRepository.login` | `POST /auth/login` |
| `AuthRepository.logout` | `POST /auth/logout` |
| `AuthRepository.requestPasswordReset` | `POST /auth/password/reset` |
| `AuthRepository.updateProfile` | `PUT /students/me` |
| `CourseRepository.getPublishedCourses` | `GET /courses?status=published` |
| `CourseRepository.searchCourses` | `GET /courses/search?q=` |
| `CourseRepository.getCoursesByCategory` | `GET /courses?category=` |
| `EnrollmentRepository.enroll` | `POST /enrollments` |
| `EnrollmentRepository.getMyEnrollments` | `GET /enrollments/me` |
| `LessonRepository.getLessonsForCourse` | `GET /courses/{id}/lessons` |
| `ProgressRepository.markLessonCompleted` | `POST /lessons/{id}/complete` |
| `ProgressRepository.getProgress` | `GET /enrollments/{id}/progress` |
| `AnnouncementRepository.getAnnouncements` | `GET /announcements` |
| `NotificationRepository.getNotifications` | `GET /notifications` |

---

## 6. Mock Data Rules

- **All seed data lives in one file:** `lib/data/mock/mock_data.dart`. No other file may hard-code sample content.
- Seed data is defined as JSON maps and converted via `Model.fromJson`, e.g.:

```dart
// lib/data/mock/mock_data.dart
class MockData {
  static final List<Map<String, dynamic>> courseJson = [
    {
      'id': 'course-001',
      'title': 'Intro to Flutter',
      'description': 'Build your first mobile app with Flutter.',
      'categoryId': 'cat-mobile-dev',
      'objectives': ['Install Flutter', 'Build a UI', 'Run on a device'],
      'difficultyLevel': 'beginner',
      'thumbnailUrl': 'https://example.com/thumbs/flutter.png',
      'isPublished': true,
      'lessonIds': ['lesson-001', 'lesson-002'],
    },
    // ... more courses
  ];

  static List<Course> get courses =>
      courseJson.map(Course.fromJson).toList();
}
```

- Provide enough seed data to exercise every module: several categories, published **and** unpublished courses, courses with multiple ordered lessons (some locked/unavailable for 4.6), resources of each type (video/audio/pdf/image), enrollments with varied progress (0%, partial, 100%), announcements, and notifications (read/unread).
- Include **one demo student account** for login (e.g. `student@demo.com` / `password123`) — login must validate against mock credentials, and wrong credentials must fail with a friendly error.
- Mock repositories may simulate latency with a small `Future.delayed` so loading states are realistic and get built.
- **In-memory means in-memory:** mock mutations happen only in the running app's data structures and reset on restart. (The REST repositories persist only the session token, server URL and notification "seen" time with `shared_preferences`.)
- Mutating mock data must go through repository methods, which update the in-memory lists in `MockData` (or the repository's own state) so all providers stay consistent.

---

## 7. Model & Coding Conventions

- **File names:** `snake_case.dart`. **Class names:** `UpperCamelCase`. **Members:** `lowerCamelCase`.
- Models are plain Dart classes: `final` fields, `const` constructor where possible, `==`/`hashCode` when compared in tests/lists, a useful `copyWith` when mutated.
- Models must not import `package:flutter` — keep them pure Dart (testable everywhere).
- Prefer `const` widgets; extract reusable pieces into `lib/ui/widgets/`.
- Use `Theme.of(context)` colors/text styles instead of hard-coded values; extend `lib/core/theme.dart` rather than styling inline.
- Async: repositories return `Future`s; providers use `async`/`await` and expose simple state (`isLoading`, `error`, data lists) for screens.
- Handle the three UI states everywhere: **loading**, **error/empty**, **content**.
- Error handling: mock repositories throw/domain-error like a real client would (e.g. login failure); providers catch and surface friendly messages. No raw exceptions reaching the UI.
- Comments: mark implemented functionality with its module ID, e.g. `// 3.1 Enroll in Course`.
- `pubspec.yaml` dependencies: add `provider` when the first provider is created. Don't add HTTP packages until the API phase.

---

## 8. Workflow for Every Change

1. Read the relevant module in §3 and the docx if details are missing.
2. Plan the change across layers (model → repository → mock data → provider → screen).
3. Implement mock-first: extend `mock_data.dart` / `Mock*Repository` as needed.
4. Run `flutter analyze` — must be clean.
5. Run `flutter test` — add/update a widget test for new screens (tap-through, state visible); tests must not depend on restart persistence or network.
6. Keep changes scoped: don't refactor unrelated code, don't add packages without need.

## 9. Definition of Done

- Feature matches the docx description for its module ID.
- All data access goes through a repository interface; UI has zero direct mock-data access.
- Mock data for the feature exists in `mock_data.dart` with realistic content.
- `flutter analyze` passes with no issues; `flutter test` passes.
- Loading, empty, and error states are handled in the UI.
