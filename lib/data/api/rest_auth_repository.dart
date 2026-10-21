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
        'This app is for students. Administrators please use the web portal.',
      );
    }

    await _api.saveToken(token);
    await _api.saveUserJson(userMap);
    return AppUser.fromJson(userMap);
  }

  /// 1.1 Registration — the server always creates a student account.
  @override
  Future<AppUser> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final res = await _api.post('/register', body: {
      'name': fullName.trim(),
      'email': email.trim(),
      'password': password,
      'password_confirmation': password,
    });

    if (!res.isSuccess) {
      throw AuthException(_api.errorMessage(res, 'Could not create your account.'));
    }

    final data = res.data is Map ? res.data as Map : const {};
    final token = data['token']?.toString() ?? '';
    final userData = data['user'];
    if (token.isEmpty || userData is! Map) {
      throw const AuthException('Unexpected response from the server.');
    }

    final userMap = Map<String, dynamic>.from(userData);
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
      await _api.clearToken(); // expired, revoked, suspended, or not a student
    }
    // Tell the student why they are back at the login screen.
    final notice = _accountNotice(res);
    if (notice != null) throw AuthException(notice);
    return null;
  }

  /// 1.2 Logout
  @override
  Future<void> logout() async {
    await _api.post('/logout');
    await _api.clearToken();
  }

  @override
  Future<bool> isSessionValid() async => (await checkSession()).valid;

  /// GET /sync answers in milliseconds; a suspended or deactivated account
  /// gets 403/401 with the reason instead.
  @override
  Future<SessionCheck> checkSession() async {
    final res = await _api.get('/sync');
    if (res.statusCode == 401 || res.statusCode == 403) {
      // A suspended account keeps its token on the server; revoke this one.
      if (res.statusCode == 403) await _api.post('/logout');
      await _api.clearToken();
      return SessionCheck(valid: false, message: _accountNotice(res));
    }
    final data = res.data;
    return SessionCheck(
      valid: true,
      version: res.isSuccess && data is Map ? data['version']?.toString() : null,
    );
  }

  /// The server's suspension/deactivation notice, if that is why it refused.
  static String? _accountNotice(ApiResponse res) {
    final data = res.data;
    if (data is Map && data['account_status'] != null) {
      return data['message']?.toString();
    }
    return null;
  }

  /// 1.3 Password Recovery — the server returns `reset_token` when the email exists.
  @override
  Future<String> requestPasswordReset(String email) async {
    final res = await _api.post('/forgot-password', body: {'email': email.trim()});
    if (!res.isSuccess) {
      throw AuthException(_api.errorMessage(res, 'Failed to request password reset.'));
    }
    final data = res.data;
    final token = data is Map ? data['reset_token'] : null;
    if (token is! String || token.isEmpty) {
      throw const AuthException('Failed to request password reset.');
    }
    return token;
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
