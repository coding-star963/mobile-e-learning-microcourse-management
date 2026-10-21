import '../../models/quiz.dart';

abstract class QuizRepository {
  Future<QuizSession> load(String courseId, String lessonId);
  Future<QuizAttempt> submit(
    String courseId,
    String lessonId,
    int revision,
    List<int> answers,
  );
}
