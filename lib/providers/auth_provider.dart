import 'package:flutter/foundation.dart';

import '../data/repositories/auth_repository.dart';
import '../models/user.dart';

/// State holder for Module 1 — Authentication & Profile Management.
/// Screens read [status], [user], and [error] via context.watch and call the
/// action methods through context.read (AGENT.md §4.4, §7).
class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthRepository repo})
      : _authRepository = repo;

  final AuthRepository _authRepository;

  AuthStatus status = AuthStatus.unauthenticated;
  AppUser? user;
  String? error;

  bool get isLoading => status == AuthStatus.authenticating ||
      status == AuthStatus.submitting;

  bool get isAuthenticated => user != null;

  /// True while a saved session is being checked on app start.
  bool isRestoring = false;

  /// 1.1 Resume a saved session (called once on app start).
  Future<void> restoreSession() async {
    isRestoring = true;
    notifyListeners();
    try {
      user = await _authRepository.restoreSession();
      status = user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
    } catch (_) {
      user = null;
      status = AuthStatus.unauthenticated;
    } finally {
      isRestoring = false;
      notifyListeners();
    }
  }

  /// 1.1 Login — validates credentials and enters the app on success.
  Future<bool> login(String email, String password) async {
    _setBusy(AuthStatus.authenticating);
    try {
      user = await _authRepository.login(email: email, password: password);
      status = AuthStatus.authenticated;
      error = null;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _fail(e.message);
      return false;
    } catch (e) {
      _fail(e.toString());
      return false;
    }
  }

  /// 1.2 Logout — ends the session and returns to the login screen.
  Future<void> logout() async {
    _setBusy(AuthStatus.submitting);
    try {
      await _authRepository.logout();
    } finally {
      user = null;
      error = null;
      status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// True unless the server rejected the saved session (e.g. an administrator
  /// deactivated this account on the web portal).
  Future<bool> isSessionValid() => _authRepository.isSessionValid();

  /// Returns to the login screen after the server ended the session.
  void endRejectedSession() {
    user = null;
    status = AuthStatus.unauthenticated;
    error = 'Your session has ended or your account was deactivated. '
        'Please log in again.';
    notifyListeners();
  }

  /// Reset token from the last successful [requestPasswordReset]; else null.
  String? resetToken;

  /// 1.3 Password Recovery — requests a reset; returns true on success.
  Future<bool> requestPasswordReset(String email) async {
    _setBusy(AuthStatus.submitting);
    resetToken = null;
    try {
      resetToken = await _authRepository.requestPasswordReset(email);
      error = null;
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _fail(e.message);
      return false;
    } catch (e) {
      _fail(e.toString());
      return false;
    }
  }

  /// 1.3 Password Recovery — sets a new password with the emailed token.
  Future<bool> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    _setBusy(AuthStatus.submitting);
    try {
      await _authRepository.resetPassword(
        email: email,
        token: token,
        newPassword: newPassword,
      );
      error = null;
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _fail(e.message);
      return false;
    } catch (e) {
      _fail(e.toString());
      return false;
    }
  }

  /// 1.4 Profile Management — uploads a new profile photo.
  Future<bool> uploadProfilePhoto({
    required List<int> bytes,
    required String fileName,
  }) async {
    final current = user;
    if (current == null) return false;
    _setBusy(AuthStatus.submitting);
    try {
      user = await _authRepository.uploadProfilePhoto(
        userId: current.id,
        bytes: bytes,
        fileName: fileName,
      );
      error = null;
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _fail(e.message);
      return false;
    } catch (e) {
      _fail(e.toString());
      return false;
    }
  }

  /// 1.4 Profile Management — refreshes the current profile from the repo.
  Future<void> loadProfile() async {
    final current = user;
    if (current == null) return;
    _setBusy(AuthStatus.submitting);
    try {
      user = await _authRepository.getProfile(current.id);
      error = null;
    } on AuthException catch (e) {
      error = e.message;
    } catch (e) {
      error = e.toString();
    } finally {
      status = AuthStatus.authenticated;
      notifyListeners();
    }
  }

  /// 1.4 Profile Management — updates name/email/photo in memory.
  Future<bool> updateProfile({
    String? fullName,
    String? email,
    String? photoUrl,
  }) async {
    final current = user;
    if (current == null) return false;
    _setBusy(AuthStatus.submitting);
    try {
      user = await _authRepository.updateProfile(
        userId: current.id,
        fullName: fullName,
        email: email,
        photoUrl: photoUrl,
      );
      error = null;
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _fail(e.message);
      return false;
    } catch (e) {
      _fail(e.toString());
      return false;
    } finally {
      if (status != AuthStatus.unauthenticated) {
        status = AuthStatus.authenticated;
      }
    }
  }

  /// 1.4 Profile Management — changes the password after verifying the current one.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final current = user;
    if (current == null) return false;
    _setBusy(AuthStatus.submitting);
    try {
      await _authRepository.changePassword(
        userId: current.id,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      error = null;
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _fail(e.message);
      return false;
    } catch (e) {
      _fail(e.toString());
      return false;
    } finally {
      if (status != AuthStatus.unauthenticated) {
        status = AuthStatus.authenticated;
      }
    }
  }

  // -- private helpers --------------------------------------------------------

  void _setBusy(AuthStatus busyStatus) {
    status = busyStatus;
    error = null;
    notifyListeners();
  }

  void _fail(String message) {
    status = user == null
        ? AuthStatus.unauthenticated
        : AuthStatus.authenticated;
    error = message;
    notifyListeners();
  }
}

enum AuthStatus { unauthenticated, authenticating, submitting, authenticated }
