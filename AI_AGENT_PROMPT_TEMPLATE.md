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
