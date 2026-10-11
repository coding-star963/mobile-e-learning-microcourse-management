import '../../models/user.dart';
import '../repositories/auth_repository.dart';
import 'api_client.dart';

/// Module 1 against the Laravel REST API. Errors are surfaced as
/// [AuthException]s; there is no fallback to mock data.
class RestAuthRepository implements AuthRepository {
  final ApiClient _api = ApiClient.instance;

  /// 1.1 Login — only student accounts may use the mobile app.
  @override
  Future<AppUser> login({required String email, required String password}) async {
    final res = await _api.post('/login', body: {
      'email': email.trim(),
      'password': password,
    });

    if (!res.isSuccess) {
      throw AuthException(_api.errorMessage(res, 'Invalid credentials or login failed.'));
    }

    final data = res.data is Map ? res.data as Map : const {};
    final token = data['token']?.toString() ?? '';
    final userData = data['user'];
    if (token.isEmpty || userData is! Map) {
      throw const AuthException('Unexpected response from the server.');
    }

    final userMap = Map<String, dynamic>.from(userData);
    if (userMap['role'] != 'student') {
      // Revoke the token that was just issued; staff use the web app.
      await _api.saveToken(token);
      await _api.post('/logout');
      await _api.clearToken();
      throw const AuthException(
        'This app is for students. Administrators and teachers please use the web portal.',
      );
    }

    await _api.saveToken(token);
    await _api.saveUserJson(userMap);
    return AppUser.fromJson(userMap);
  }

  /// 1.1 Resume the saved session if its token is still valid.
  @override
  Future<AppUser?> restoreSession() async {
    final token = await _api.getToken();
    if (token == null || token.isEmpty) return null;

    final res = await _api.get('/user');
    final userMap = res.isSuccess ? ApiClient.dataItem(res.data) : null;
    if (userMap != null && userMap['role'] == 'student') {
      await _api.saveUserJson(userMap);
      return AppUser.fromJson(userMap);
    }
    if (res.statusCode == 401 || res.statusCode == 403 || userMap != null) {
      await _api.clearToken(); // expired, revoked, or not a student
    }
    return null;
  }

  /// 1.2 Logout
  @override
  Future<void> logout() async {
    await _api.post('/logout');
    await _api.clearToken();
  }

  @override
  Future<bool> isSessionValid() async {
    final res = await _api.get('/user');
    if (res.statusCode == 401 || res.statusCode == 403) {
      await _api.clearToken();
      return false;
    }
    return true;
  }

  /// 1.3 Password Recovery — the reset instructions are emailed by the server.
  /// A local backend also returns the token as `dev_token`.
  @override
  Future<String?> requestPasswordReset(String email) async {
    final res = await _api.post('/forgot-password', body: {'email': email.trim()});
    if (!res.isSuccess) {
      throw AuthException(_api.errorMessage(res, 'Failed to request password reset.'));
    }
    final data = res.data;
    return data is Map ? data['dev_token'] as String? : null;
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    final res = await _api.post('/reset-password', body: {
      'email': email.trim(),
      'token': token.trim(),
      'password': newPassword,
      'password_confirmation': newPassword,
    });
    if (!res.isSuccess) {
      throw AuthException(_api.errorMessage(res, 'Could not reset your password.'));
    }
  }

  /// 1.4 Profile Management
  @override
  Future<AppUser> uploadProfilePhoto({
    required String userId,
    required List<int> bytes,
    required String fileName,
  }) async {
    final res = await _api.postFile('/profile/photo', field: 'photo', bytes: bytes, fileName: fileName);
    final userMap = res.isSuccess ? ApiClient.dataItem(res.data, 'user') : null;
    if (userMap == null) {
      throw AuthException(_api.errorMessage(res, 'Could not upload your photo.'));
    }
    await _api.saveUserJson(userMap);
    return AppUser.fromJson(userMap);
  }

  @override
  Future<AppUser> getProfile(String userId) async {
    final res = await _api.get('/user');
    final userMap = res.isSuccess ? ApiClient.dataItem(res.data) : null;
    if (userMap == null) {
      throw AuthException(_api.errorMessage(res, 'Could not load your profile.'));
    }
    return AppUser.fromJson(userMap);
  }

  @override
  Future<AppUser> updateProfile({
    required String userId,
    String? fullName,
    String? email,
    String? photoUrl,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['name'] = fullName;
    if (email != null) body['email'] = email;

    final res = await _api.put('/profile', body: body);
    final userMap = res.isSuccess ? ApiClient.dataItem(res.data, 'user') : null;
    if (userMap == null) {
      throw AuthException(_api.errorMessage(res, 'Could not update your profile.'));
    }
    await _api.saveUserJson(userMap);
    return AppUser.fromJson(userMap);
  }

  @override
  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await _api.put('/profile/password', body: {
      'current_password': currentPassword,
      'password': newPassword,
      'password_confirmation': newPassword,
    });

    if (!res.isSuccess) {
      throw AuthException(_api.errorMessage(res, 'Password change failed.'));
    }
  }
}
