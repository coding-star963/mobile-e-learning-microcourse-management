/// App-wide constants (AGENT.md §4.2).
class AppConstants {
  const AppConstants._();

  static const String appName = 'MicroLearn';
  static const String appTagline = 'E-Learning & Micro-Course System';

  /// Demo student account for the mock phase (AGENT.md §6).
  static const String demoEmail = 'alex.rivera@gmail.com';
  static const String demoPassword = 'password123';

  /// The demo student's id, matching the enrollment seeds (AGENT.md §6).
  static const String demoStudentId = 'student-001';

  /// Simulated network latency for mock repositories (AGENT.md §6).
  static const Duration mockLatency = Duration(milliseconds: 300);

  /// How often open screens re-check the server so changes made on the web
  /// portal appear on the phone without a manual refresh.
  static const Duration autoRefreshInterval = Duration(seconds: 10);
}
