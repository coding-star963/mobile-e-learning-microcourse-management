import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../data/repositories/quiz_repository.dart';
import '../../../models/quiz.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.courseId,
    required this.lessonId,
    required this.repository,
  });

  final String courseId;
  final String lessonId;
  final QuizRepository repository;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  LessonQuiz? _quiz;
  QuizAttempt? _result;
  List<int?> _answers = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await widget.repository.load(
        widget.courseId,
        widget.lessonId,
      );
      if (!mounted) return;
      setState(() {
        _quiz = session.quiz;
        _result = session.latestAttempt;
        _answers = List<int?>.filled(session.quiz.questions.length, null);
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_saving || _answers.any((answer) => answer == null)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await widget.repository.submit(
        widget.courseId,
        widget.lessonId,
        _quiz!.revision,
        _answers.cast<int>(),
      );
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiz = _quiz;
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('Lesson Quiz')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _saving ? null : _load,
                        child: const Text('Reload Quiz'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (quiz != null) ...[
                    Text(
                      quiz.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (quiz.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(quiz.description),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      '${quiz.questions.length} ${quiz.questions.length == 1 ? 'question' : 'questions'} • Passing score: ${quiz.passingScore}%',
                    ),
                    const SizedBox(height: 20),
                    if (result != null) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                result.passed ? 'Passed' : 'Not passed yet',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: result.passed
                                      ? AppTheme.accentEmerald
                                      : Theme.of(context).colorScheme.error,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${result.score.toStringAsFixed(result.score % 1 == 0 ? 0 : 2)}% • ${result.correctCount} of ${result.questionCount} correct',
                              ),
                              Text(
                                'Passing score for this attempt: ${result.passingScore}%',
                              ),
                              if (result.revision != quiz.revision)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Text(
                                    'This result is from an earlier version. Take the updated quiz below.',
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => setState(() {
                          _result = null;
                          _error = null;
                          _answers = List<int?>.filled(
                            quiz.questions.length,
                            null,
                          );
                        }),
                        icon: const Icon(Icons.refresh),
                        label: Text(
                          result.revision == quiz.revision
                              ? 'Retake Quiz'
                              : 'Take Updated Quiz',
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Answer Review',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      ...result.results.asMap().entries.map(
                        (entry) => Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${entry.key + 1}. ${entry.value.question}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Your answer: ${entry.value.options[entry.value.selectedAnswer]}',
                                ),
                                Text(
                                  entry.value.isCorrect
                                      ? 'Correct'
                                      : 'Correct answer: ${entry.value.options[entry.value.correctAnswer]}',
                                  style: TextStyle(
                                    color: entry.value.isCorrect
                                        ? AppTheme.accentEmerald
                                        : Theme.of(context).colorScheme.error,
                                  ),
                                ),
                                if (entry.value.explanation.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(entry.value.explanation),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      ...quiz.questions.asMap().entries.map(
                        (entry) => Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${entry.key + 1}. ${entry.value.question}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...entry.value.options.asMap().entries.map(
                                  (option) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        alignment: Alignment.centerLeft,
                                        minimumSize: const Size(
                                          double.infinity,
                                          48,
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        backgroundColor:
                                            _answers[entry.key] == option.key
                                            ? AppTheme.goldPrimary.withValues(
                                                alpha: 0.15,
                                              )
                                            : null,
                                      ),
                                      onPressed: _saving
                                          ? null
                                          : () => setState(
                                              () => _answers[entry.key] =
                                                  option.key,
                                            ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            _answers[entry.key] == option.key
                                                ? Icons.radio_button_checked
                                                : Icons.radio_button_unchecked,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(child: Text(option.value)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${_answers.where((answer) => answer != null).length} of ${quiz.questions.length} answered. Answer every question to submit.',
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed:
                            _saving || _answers.any((answer) => answer == null)
                            ? null
                            : _submit,
                        child: Text(_saving ? 'Submitting...' : 'Submit Quiz'),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Your score is saved separately from lesson completion. You can retake this quiz.',
                      ),
                    ],
                  ],
                ],
              ),
            ),
    );
  }
}
