import '../../models/user.dart';
import '../mock/mock_auth_repository.dart';
import '../repositories/auth_repository.dart';
import 'api_client.dart';

class RestAuthRepository implements AuthRepository {
  final ApiClient _api = ApiClient.instance;
  final MockAuthRepository _mockFallback = MockAuthRepository();

  @override
  Future<AppUser> login({required String email, required String password}) async {
    final res = await _api.post('/login', body: {
      'email': email.trim(),
      'password': password,
    });

    if (res.isSuccess && res.data is Map) {
      final data = res.data as Map<String, dynamic>;
      final token = data['token']?.toString() ?? '';
      if (token.isNotEmpty) {
        await _api.saveToken(token);
      }
      final userData = data['user'];
      if (userData is Map) {
        final map = Map<String, dynamic>.from(userData);
        await _api.saveUserJson(map);
        return AppUser.fromJson(map);
      }
    }

    // If server unreachable or error:
    if (res.statusCode == 0) {
      // Backend not running on this host yet; use fallback so developer can still test
      try {
        return await _mockFallback.login(email: email, password: password);
      } catch (_) {
        throw const AuthException(
          'Unable to reach backend server. Please verify server IP in settings.',
        );
      }
    }

    throw AuthException(res.message ?? 'Invalid credentials or login failed.');
  }

  @override
  Future<void> logout() async {
    try {
      await _api.post('/logout');
    } catch (_) {}
    await _api.clearToken();
    await _mockFallback.logout();
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    final res = await _api.post('/forgot-password', body: {'email': email.trim()});
    if (!res.isSuccess && res.statusCode != 0) {
      throw AuthException(res.message ?? 'Failed to request password reset.');
    }
    if (res.statusCode == 0) {
      await _mockFallback.requestPasswordReset(email);
    }
  }

  @override
  Future<AppUser> getProfile(String userId) async {
    final res = await _api.get('/user');
    if (res.isSuccess && res.data is Map) {
      final data = res.data as Map<String, dynamic>;
      final userMap = data.containsKey('data') ? data['data'] : data;
      if (userMap is Map) {
        return AppUser.fromJson(Map<String, dynamic>.from(userMap));
      }
    }
    return _mockFallback.getProfile(userId);
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
    if (res.isSuccess && res.data is Map) {
      final data = res.data as Map<String, dynamic>;
      final userMap = data['user'] ?? data['data'] ?? data;
      if (userMap is Map) {
        return AppUser.fromJson(Map<String, dynamic>.from(userMap));
      }
    }
    return _mockFallback.updateProfile(
      userId: userId,
      fullName: fullName,
      email: email,
      photoUrl: photoUrl,
    );
  }

  @override
  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await _api.put('/profile/password', body: {
      'current_password': currentPassword,
      'new_password': newPassword,
      'new_password_confirmation': newPassword,
    });

    if (!res.isSuccess && res.statusCode != 0) {
      throw AuthException(res.message ?? 'Password change failed.');
    }
    if (res.statusCode == 0) {
      await _mockFallback.changePassword(
        userId: userId,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    }
  }
}
