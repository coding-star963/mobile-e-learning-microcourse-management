import '../../models/user.dart';

/// Domain error thrown by [AuthRepository] implementations — providers catch
/// this and surface the message to the UI (AGENT.md §7).
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Contract for Module 1 — Authentication & Profile Management (AGENT.md §4.3).
/// Methods align with the future REST endpoints in AGENT.md §5.
abstract class AuthRepository {
  /// 1.1 Login — validates credentials and returns the signed-in student.
  /// Throws [AuthException] on invalid credentials.
  Future<AppUser> login({required String email, required String password});

  /// 1.1 Login — resumes a saved session on app start (null = log in again).
  Future<AppUser?> restoreSession();

  /// 1.2 Logout — ends the authenticated session.
  Future<void> logout();

  /// False only when the server rejects the saved session (expired, revoked,
  /// or deactivated account). Network errors count as valid.
  Future<bool> isSessionValid();

  /// 1.3 Password Recovery — requests a password reset for the given email.
  /// Returns the reset token only when the server runs locally (no real email);
  /// otherwise null. Throws [AuthException] if the email is not recognized.
  Future<String?> requestPasswordReset(String email);

  /// 1.3 Password Recovery — sets a new password using the emailed reset token.
  /// Throws [AuthException] when the token is invalid or expired.
  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  });

  /// 1.4 Profile Management — uploads a new profile photo.
  Future<AppUser> uploadProfilePhoto({
    required String userId,
    required List<int> bytes,
    required String fileName,
  });

  /// 1.4 Profile Management — returns the current student's profile.
  Future<AppUser> getProfile(String userId);

  /// 1.4 Profile Management — updates basic profile info (name, email, photo).
  Future<AppUser> updateProfile({
    required String userId,
    String? fullName,
    String? email,
    String? photoUrl,
  });

  /// 1.4 Profile Management — changes the password (requires the current one).
  /// Throws [AuthException] when the current password is wrong.
  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  });
}
