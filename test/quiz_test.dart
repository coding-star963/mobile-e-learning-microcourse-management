import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_e_learning_micro_course_system/data/repositories/quiz_repository.dart';
import 'package:mobile_e_learning_micro_course_system/models/lesson.dart';
import 'package:mobile_e_learning_micro_course_system/models/quiz.dart';
import 'package:mobile_e_learning_micro_course_system/ui/screens/lesson/quiz_screen.dart';

const quiz = LessonQuiz(
  title: 'HTML Quiz',
  description: 'Choose the best answer.',
  revision: 2,
  passingScore: 70,
  questions: [
    QuizQuestion(
      question: 'Which element embeds video?',
      options: ['video', 'table'],
    ),
    QuizQuestion(
      question: 'Which attribute shows playback controls?',
      options: ['hidden', 'controls'],
    ),
  ],
);
const attempt = QuizAttempt(
  title: 'HTML Quiz',
  revision: 2,
  score: 100,
  passingScore: 70,
  correctCount: 2,
  questionCount: 2,
  passed: true,
  results: [
    QuizAnswerResult(
      question: 'Which element embeds video?',
      options: ['video', 'table'],
      selectedAnswer: 0,
      correctAnswer: 0,
      isCorrect: true,
      explanation: 'The video element embeds a player.',
    ),
    QuizAnswerResult(
      question: 'Which attribute shows playback controls?',
      options: ['hidden', 'controls'],
      selectedAnswer: 1,
      correctAnswer: 1,
      isCorrect: true,
      explanation: '',
    ),
  ],
);

class FakeQuizRepository implements QuizRepository {
  QuizAttempt? latest;
  bool failLoad = false;
  bool failSubmit = false;
  int submissions = 0;
  int? submittedRevision;
  List<int>? submittedAnswers;
  Completer<QuizAttempt>? pending;

  @override
  Future<QuizSession> load(String courseId, String lessonId) async {
    if (failLoad) throw Exception('This lesson is not available yet.');
    return QuizSession(quiz: quiz, latestAttempt: latest);
  }

  @override
  Future<QuizAttempt> submit(
    String courseId,
    String lessonId,
    int revision,
    List<int> answers,
  ) async {
    submissions++;
    submittedRevision = revision;
    submittedAnswers = List<int>.from(answers);
    if (failSubmit) {
      throw Exception('This quiz has changed. Reload it and try again.');
    }
    if (pending != null) return pending!.future;
    latest = attempt;
    return attempt;
  }
}

void main() {
  Future<void> open(WidgetTester tester, FakeQuizRepository repo) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: QuizScreen(courseId: '1', lessonId: '1', repository: repo),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> answerAll(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(OutlinedButton, 'video'));
    await tester.pump();
    await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'controls'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'controls'));
    await tester.pump();
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Submit Quiz'),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'mobile quiz requires every answer and submits the revision for server grading',
    (tester) async {
      final repo = FakeQuizRepository();
      await open(tester, repo);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Submit Quiz'),
            )
            .onPressed,
        isNull,
      );
      await answerAll(tester);
      await tester.tap(find.text('Submit Quiz'));
      await tester.pumpAndSettle();
      expect(repo.submittedRevision, 2);
      expect(repo.submittedAnswers, [0, 1]);
      expect(find.text('Passed'), findsOneWidget);
      expect(find.text('100% • 2 of 2 correct'), findsOneWidget);
      expect(find.text('Answer Review'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('saved score reopens and retake clears the prior answers', (
    tester,
  ) async {
    final repo = FakeQuizRepository()..latest = attempt;
    await open(tester, repo);
    expect(find.text('Passed'), findsOneWidget);
    await tester.tap(find.text('Retake Quiz'));
    await tester.pumpAndSettle();
    expect(find.text('Passed'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Submit Quiz'),
          )
          .onPressed,
      isNull,
    );
    expect(repo.submissions, 0);
  });

  testWidgets(
    'stale quiz submission displays the server message and can reload',
    (tester) async {
      final repo = FakeQuizRepository()..failSubmit = true;
      await open(tester, repo);
      await answerAll(tester);
      await tester.tap(find.text('Submit Quiz'));
      await tester.pumpAndSettle();
      expect(find.textContaining('This quiz has changed.'), findsOneWidget);
      await tester.ensureVisible(find.text('Reload Quiz'));
      await tester.tap(find.text('Reload Quiz'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Submit Quiz'),
            )
            .onPressed,
        isNull,
      );
      expect(find.text('Passed'), findsNothing);
    },
  );

  testWidgets('submission stays disabled while waiting for the server', (
    tester,
  ) async {
    final repo = FakeQuizRepository()..pending = Completer<QuizAttempt>();
    await open(tester, repo);
    await answerAll(tester);
    await tester.tap(find.text('Submit Quiz'));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Submitting...'),
          )
          .onPressed,
      isNull,
    );
    expect(repo.submissions, 1);
    repo.pending!.complete(attempt);
    await tester.pumpAndSettle();
    expect(find.text('Passed'), findsOneWidget);
  });

  testWidgets('unavailable quiz offers retry without exposing questions', (
    tester,
  ) async {
    final repo = FakeQuizRepository()..failLoad = true;
    await open(tester, repo);
    expect(
      find.textContaining('This lesson is not available yet.'),
      findsOneWidget,
    );
    expect(find.text('HTML Quiz'), findsNothing);
    repo.failLoad = false;
    await tester.tap(find.text('Reload Quiz'));
    await tester.pumpAndSettle();
    expect(find.text('HTML Quiz'), findsOneWidget);
  });

  test('lesson quiz summary survives JSON cache round trip', () {
    final lesson = Lesson.fromJson({
      'id': 1,
      'course_id': 1,
      'title': 'HTML',
      'quiz': {'title': 'HTML Quiz', 'question_count': 2},
    });
    expect(lesson.hasQuiz, isTrue);
    expect(Lesson.fromJson(lesson.toJson()).quizTitle, 'HTML Quiz');
    expect(Lesson.fromJson(lesson.toJson()).quizQuestionCount, 2);
    expect(
      const Lesson(
        id: '2',
        courseId: '1',
        title: 'No quiz',
        description: '',
      ).hasQuiz,
      isFalse,
    );
  });
}
