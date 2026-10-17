/// Shared form validators (mirror the API's validation rules).
class Validators {
  const Validators._();

  static final RegExp _gmail = RegExp(r'^[^@\s]+@gmail\.com$', caseSensitive: false);

  static const String gmailError =
      'Only Gmail addresses are allowed (ending in @gmail.com).';

  /// Every email entered in the app must be a Gmail address (name@gmail.com).
  static bool isGmail(String email) => _gmail.hasMatch(email.trim());

  /// Form validator for every email field: required and Gmail only.
  static String? gmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your Gmail address.';
    if (!isGmail(v)) return gmailError;
    return null;
  }
}
