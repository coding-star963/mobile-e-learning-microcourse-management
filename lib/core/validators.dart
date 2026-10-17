/// Shared form validators (mirror the API's validation rules).
class Validators {
  const Validators._();

  static final RegExp _gmail = RegExp(r'^[^@\s]+@gmail\.com$', caseSensitive: false);

  static const String gmailError =
      'Student accounts must use a Gmail address (ending in @gmail.com).';

  /// Student accounts may only use a Gmail address (name@gmail.com).
  static bool isGmail(String email) => _gmail.hasMatch(email.trim());
}
