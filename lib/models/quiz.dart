class QuizQuestion {
  const QuizQuestion({required this.question, required this.options});

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
    question: json['question'] as String,
    options: List<String>.from(json['options'] as List),
  );

  final String question;
  final List<String> options;
}

class LessonQuiz {
  const LessonQuiz({
    required this.title,
    required this.description,
    required this.revision,
    required this.passingScore,
    required this.questions,
  });

  factory LessonQuiz.fromJson(Map<String, dynamic> json) => LessonQuiz(
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    revision: json['revision'] as int,
    passingScore: json['passing_score'] as int,
    questions: (json['questions'] as List)
        .map((q) => QuizQuestion.fromJson(Map<String, dynamic>.from(q as Map)))
        .toList(),
  );

  final String title;
  final String description;
  final int revision;
  final int passingScore;
  final List<QuizQuestion> questions;
}

class QuizAnswerResult {
  const QuizAnswerResult({
    required this.question,
    required this.options,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.explanation,
  });

  factory QuizAnswerResult.fromJson(Map<String, dynamic> json) =>
      QuizAnswerResult(
        question: json['question'] as String,
        options: List<String>.from(json['options'] as List),
        selectedAnswer: json['selected_answer'] as int,
        correctAnswer: int.parse(json['correct_answer'].toString()),
        isCorrect: json['is_correct'] as bool,
        explanation: json['explanation'] as String? ?? '',
      );

  final String question;
  final List<String> options;
  final int selectedAnswer;
  final int correctAnswer;
  final bool isCorrect;
  final String explanation;
}

class QuizAttempt {
  const QuizAttempt({
    required this.title,
    required this.revision,
    required this.score,
    required this.passingScore,
    required this.correctCount,
    required this.questionCount,
    required this.passed,
    required this.results,
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> json) => QuizAttempt(
    title: json['quiz_title'] as String,
    revision: json['revision'] as int,
    score: (json['score'] as num).toDouble(),
    passingScore: json['passing_score'] as int,
    correctCount: json['correct_count'] as int,
    questionCount: json['question_count'] as int,
    passed: json['passed'] as bool,
    results: (json['results'] as List)
        .map(
          (q) => QuizAnswerResult.fromJson(Map<String, dynamic>.from(q as Map)),
        )
        .toList(),
  );

  final String title;
  final int revision;
  final double score;
  final int passingScore;
  final int correctCount;
  final int questionCount;
  final bool passed;
  final List<QuizAnswerResult> results;
}

class QuizSession {
  const QuizSession({required this.quiz, this.latestAttempt});
  final LessonQuiz quiz;
  final QuizAttempt? latestAttempt;
}
