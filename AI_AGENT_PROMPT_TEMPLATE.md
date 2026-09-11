# AI Agent Prompt Template — E-Learning Micro-Course App (Student Side)

> Copy this template, fill in every `[...]` field, and paste the result as the prompt for an AI coding agent.
> The agent must read `AGENT.md` first — this template only carries the per-task specifics.

---

## 1. Task header

- **Task title:** `[One-line description of what to build or change]`
- **Module / Function ID (from AGENT.md §3 / requirements doc):** `[e.g. 2.2 Search Courses]`
- **Task type:** `[new feature | enhancement | bug fix | refactor | test only]`
- **Priority:** `[must have | nice to have]`

## 2. What to build

Describe the behavior in user terms:

- **As a student, I want** `[capability]` **so that** `[benefit]`.
- Acceptance criteria:
  - `[Criterion 1 — observable in the UI, e.g. typing in the search field filters the course list live]`
  - `[Criterion 2]`
  - `[Criterion 3]`

## 3. Required workflow (agent must follow)

1. **Read `AGENT.md` fully**, especially §3 (module list), §4 (architecture), §5 (API migration plan), and §6 (mock data rules).
2. If the module/function description is unclear, re-read the source doc `E_Learning_Micro_Course_Mobile_User_Functionalities.docx` description for that ID before coding.
3. Plan the change across all layers **bottom-up**: model → repository contract → mock data → mock repository → provider → screen/widget.
4. Implement with mock data only (in-memory, seeded in `lib/data/mock/mock_data.dart`). No HTTP calls, no persistence.
5. Keep the REST-API swap possible: models use `fromJson`/`toJson`, data access only via repository interfaces, UI never touches `MockData` directly.

## 4. Constraints & rules (from AGENT.md)

- State management: **Provider** (`ChangeNotifier`); screens use `context.watch`/`context.read`.
- No new packages without stating the reason; `provider` is already the allowed dependency.
- Data flow is one-way downward: UI → Provider → Repository interface → Mock implementation.
- Mutations go through repository methods so all providers stay consistent.
- Every UI feature handles **loading, empty/error, and content** states.
- Comment implemented functions with the module ID: `// 2.2 Search Courses`.
- Code must pass `flutter analyze` and `flutter test` with zero issues.
- Out of scope: admin/teacher management features, real backend integration, local persistence.

## 5. Mock data checklist (adapt as needed)

- [ ] Seed data added/extended in `lib/data/mock/mock_data.dart` as JSON maps parsed via `Model.fromJson`
- [ ] Realistic content (names, titles, descriptions — no "test 1", "lorem ipsum")
- [ ] Enough variety to show all UI states (e.g. published + unpublished, different difficulty levels, 0%/partial/100% progress, read + unread notifications)
- [ ] Demo student account still works: `student@demo.com` / `password123`

## 6. Files expected to change

List expected touch points (adjust to the task):

```
lib/models/[model].dart
lib/data/repositories/[contract].dart
lib/data/mock/mock_data.dart
lib/data/mock/mock_[repo].dart
lib/providers/[provider].dart
lib/ui/screens/[area]/[screen].dart
test/[screen]_widget_test.dart
```

## 7. Definition of done

- [ ] All acceptance criteria in §2 are met
- [ ] All data access goes through a repository interface
- [ ] Mock data for this feature exists and is realistic
- [ ] Loading / empty / error states handled in the UI
- [ ] `flutter analyze`: no issues
- [ ] `flutter test`: all passing, including a new/updated widget test for the feature
- [ ] Code comments reference the module/function ID
- [ ] No changes to unrelated files; no admin/teacher features added

## 8. Report back (agent fills in when done)

- What was implemented (and how it maps to the module ID):
- Files created/changed:
- Mock data added:
- `flutter analyze` / `flutter test` results:
- Notes for the future REST API phase (e.g. suggested endpoint for this feature):

---

## 9. Module-by-module development guide

**How to use this file:** make **one copy of §1–§8 per task**. A module may take one or several tasks, but never mix two modules in one prompt. Build in this order — each module depends on the one before it:

| Build order | Module | Why this position |
|---|---|---|
| 1 | Module 1 — Authentication & Profile | A logged-in student is required by everything else |
| 2 | Module 2 — Course Discovery & Browsing | The mock course catalog feeds every later module |
| 3 | Module 3 — Course Enrollment | Needs courses from Module 2 |
| 4 | Module 4 — Lessons & Learning Content | Needs enrolled courses from Module 3 |
| 5 | Module 5 — Learning Progress | Tracks completion of Module 4 lessons |
| 6 | Module 6 — Announcements & Notifications | References enrolled courses from Module 3 |
| 7 | Module 7 — Student Dashboard | Aggregates data from Modules 2–6, so it goes last |

Pre-filled §1 + §2 blocks below — paste one into a fresh copy of §1–§8 and send it to the agent:

### Sprint 1 — Module 1: Authentication & Profile (1.1–1.4)
- **Task title:** Build login, logout, password recovery, and profile screens backed by the mock auth repository
- **Module / Function ID:** 1.1, 1.2, 1.3, 1.4
- **Acceptance criteria:**
  - Login with `student@demo.com` / `password123` succeeds and lands on a home/dashboard shell; wrong credentials show a friendly error
  - Logout ends the session and returns to the login screen
  - Password recovery shows a mock "reset link sent" confirmation flow
  - Profile screen displays the demo student and allows editing name/email in memory

### Sprint 2 — Module 2: Course Discovery & Browsing (2.1–2.5)
- **Task title:** Build the course catalog with search, category filtering, course details, and status badges on mock data
- **Module / Function ID:** 2.1, 2.2, 2.3, 2.4, 2.5
- **Acceptance criteria:**
  - Catalog lists all published mock courses (2.1) with thumbnail, difficulty, and status (2.5)
  - Typing in the search field filters the list by title/keywords (2.2)
  - Tapping a category chip filters the list (2.3)
  - Course detail page shows title, description, category, objectives, difficulty, thumbnail, and lessons (2.4)

### Sprint 3 — Module 3: Course Enrollment (3.1–3.4)
- **Task title:** Build enroll action and the My Courses list backed by the mock enrollment repository
- **Module / Function ID:** 3.1, 3.2, 3.3, 3.4
- **Acceptance criteria:**
  - Enroll button on course detail adds an in-memory enrollment and updates all providers (3.1)
  - My Courses lists the student's enrollments (3.2) with enrollment details (3.3)
  - Tapping an enrolled course opens it for learning (3.4); enrolling twice is prevented

### Sprint 4 — Module 4: Lessons & Learning Content (4.1–4.6)
- **Task title:** Build the lesson list and lesson detail with video/audio playback and learning resources on mock data
- **Module / Function ID:** 4.1, 4.2, 4.3, 4.4, 4.5, 4.6
- **Acceptance criteria:**
  - Lessons appear in the teacher-arranged order (4.5) with availability/lock state (4.6)
  - Lesson detail shows title, description, and content (4.2)
  - Mock video/audio player screen opens for media lessons (4.3)
  - Resources (PDF/doc/image) are viewable and a mock download action exists (4.4)

### Sprint 5 — Module 5: Learning Progress (5.1–5.5)
- **Task title:** Build lesson completion tracking, progress display, and continue-learning on mock data
- **Module / Function ID:** 5.1, 5.2, 5.3, 5.4, 5.5
- **Acceptance criteria:**
  - Marking a lesson complete persists in memory and updates all providers (5.1)
  - Course progress bar and completion percentage reflect completed lessons (5.2, 5.3)
  - Learning history lists activity and completed courses (5.4)
  - Continue button reopens the course at the first incomplete lesson (5.5)

### Sprint 6 — Module 6: Announcements & Notifications (6.1–6.4)
- **Task title:** Build announcements and notifications screens with history on mock data
- **Module / Function ID:** 6.1, 6.2, 6.3, 6.4
- **Acceptance criteria:**
  - Announcements for enrolled courses are readable (6.1); course-update items appear as notifications (6.2)
  - Notification list shows read/unread state and marks items read on open (6.3)
  - A history screen lists previously received announcements/notifications (6.4)

### Sprint 7 — Module 7: Student Dashboard (7.1–7.4)
- **Task title:** Build the dashboard aggregating enrolled courses, progress, and recent announcements
- **Module / Function ID:** 7.1, 7.2, 7.3, 7.4
- **Acceptance criteria:**
  - Dashboard shows enrolled/ongoing course summary (7.2), progress summary (7.3), and recent announcements (7.4) from the other providers (7.1)
  - Continue-learning shortcut from Module 5 works from the dashboard
  - Empty states render correctly for a fresh student with no enrollments

> Tip: if a sprint feels too big for one prompt (Module 4 is the usual suspect), split it into multiple tasks — e.g. "4.1–4.2 lesson list/detail" then "4.3–4.4 media & resources" — using one template copy each.
