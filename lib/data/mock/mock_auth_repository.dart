import '../../core/constants.dart';
import '../../models/user.dart';
import '../repositories/auth_repository.dart';
import 'mock_data.dart';

/// Mock implementation of [AuthRepository] — validates against the seed
/// accounts in [MockData] and mutates in-memory state (resets on restart).
class MockAuthRepository implements AuthRepository {
  /// 1.1 Login — validates credentials against the registered mock accounts.
  @override
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(AppConstants.mockLatency); // simulate latency
    final key = email.toLowerCase().trim();
    final account = MockData.accountJsonByName[key];
    if (account == null || account['password'] != password) {
      throw const AuthException('Incorrect email or password.');
    }
    return MockData.userFor(key);
  }

  /// 1.1 No saved sessions in the in-memory mock phase.
  @override
  Future<AppUser?> restoreSession() async => null;

  /// 1.2 Logout — mock session ends client-side; nothing to invalidate.
  @override
  Future<void> logout() async {
    await Future<void>.delayed(AppConstants.mockLatency);
  }

  /// 1.3 Password Recovery — records the reset request; fails for unknown emails.
  @override
  Future<void> requestPasswordReset(String email) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    final key = email.toLowerCase().trim();
    if (!MockData.accountExists(key)) {
      throw const AuthException('No account found with that email address.');
    }
    MockData.passwordResetRequests.add(key);
  }

  /// 1.3 Password Recovery — accepts any token for an email that requested a reset.
  @override
  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    final key = email.toLowerCase().trim();
    if (!MockData.passwordResetRequests.contains(key) || token.trim().isEmpty) {
      throw const AuthException('The provided password reset token is invalid.');
    }
    MockData.accountJsonByName[key]!['password'] = newPassword;
    MockData.passwordResetRequests.remove(key);
  }

  /// 1.4 Profile Management — records the uploaded file name in memory.
  @override
  Future<AppUser> uploadProfilePhoto({
    required String userId,
    required List<int> bytes,
    required String fileName,
  }) =>
      updateProfile(userId: userId, photoUrl: 'mock-upload://$fileName');

  /// 1.4 Profile Management — returns the student's profile (seed + overrides).
  @override
  Future<AppUser> getProfile(String userId) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    final email = _emailForUser(userId);
    if (email == null) {
      throw const AuthException('Student profile not found.');
    }
    return MockData.userFor(email);
  }

  /// 1.4 Profile Management — applies name/email/photo updates in memory.
  @override
  Future<AppUser> updateProfile({
    required String userId,
    String? fullName,
    String? email,
    String? photoUrl,
  }) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    final currentEmail = _emailForUser(userId);
    if (currentEmail == null) {
      throw const AuthException('Student profile not found.');
    }

    final overrides = MockData.profileOverrides.putIfAbsent(userId, () => {});
    if (fullName != null) overrides['fullName'] = fullName;
    if (photoUrl != null) overrides['photoUrl'] = photoUrl;

    if (email != null && email.toLowerCase().trim() != currentEmail) {
      final newKey = email.toLowerCase().trim();
      if (MockData.accountExists(newKey)) {
        throw const AuthException('That email is already in use.');
      }
      // Move the account under the new email key so login follows the update.
      MockData.accountJsonByName[newKey] =
          Map<String, dynamic>.from(MockData.accountJsonByName[currentEmail]!);
      MockData.accountJsonByName.remove(currentEmail);
      overrides['email'] = email;
      return MockData.userFor(newKey);
    }
    return MockData.userFor(currentEmail);
  }

  /// 1.4 Profile Management — verifies the current password before changing it.
  @override
  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    final entry = _accountEntryFor(userId);
    if (entry == null) {
      throw const AuthException('Student profile not found.');
    }
    if (entry['password'] != currentPassword) {
      throw const AuthException('Current password is incorrect.');
    }
    entry['password'] = newPassword;
  }

  // -- private helpers --------------------------------------------------------

  Map<String, dynamic>? _accountEntryFor(String userId) {
    for (final account in MockData.accountJsonByName.values) {
      if ((account['user'] as Map)['id'] == userId) return account;
    }
    return null;
  }

  String? _emailForUser(String userId) {
    final entry = _accountEntryFor(userId);
    return entry == null ? null : (entry['user'] as Map)['email'] as String;
  }
}
