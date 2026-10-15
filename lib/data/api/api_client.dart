import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Error from the REST API with a message that is safe to show to students.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode = 0});

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

class ApiResponse {
  final int statusCode;
  final dynamic data;
  final bool isSuccess;
  final String? message;

  const ApiResponse({
    required this.statusCode,
    required this.data,
    required this.isSuccess,
    this.message,
  });
}

/// Central HTTP REST API Client for communicating with the Laravel backend.
/// Works on physical mobile devices over local Wi-Fi, Android emulator, and browser/Edge.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  // Keys
  static const String _tokenKey = 'auth_bearer_token';
  static const String _userKey = 'auth_user_json';
  static const String _serverUrlKey = 'backend_server_url';
  static const String _lastDartDefineKey = 'last_dart_define_base_url';

  static const String _defaultLanIp = '192.168.8.62';
  static const String _staleLanIp = '192.168.8.56';

  // Default server address:
  // Build override -> flutter run --dart-define=API_BASE_URL=http://<laptop-ip>:8000/api
  // Through ngrok  -> flutter build apk --dart-define=API_BASE_URL=https://<your-domain>.ngrok-free.app/api
  // On Edge/Web -> http://127.0.0.1:8000/api
  // On physical mobile -> http://192.168.8.62:8000/api (local Wi-Fi LAN IP)
  // It can also be changed in the app: long-press the logo on the login screen,
  // or use Server Endpoint on the profile screen.
  static const String _buildBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Normalizes any input URL by trimming whitespace, stripping trailing slashes,
  /// and ensuring it ends with `/api`.
  static String normalizeUrl(String url) {
    var cleaned = url.trim();
    while (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    if (!cleaned.endsWith('/api')) {
      cleaned = '$cleaned/api';
    }
    return cleaned;
  }

  static String get defaultBaseUrl {
    if (_buildBaseUrl.isNotEmpty) {
      return normalizeUrl(_buildBaseUrl);
    }
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }
    return 'http://$_defaultLanIp:8000/api';
  }

  /// Generous enough for slow Wi-Fi and for requests that send email (password reset).
  static const Duration _timeout = Duration(seconds: 20);

  String? _cachedBaseUrl;
  String? _cachedToken;

  Future<String> get baseUrl async {
    if (_cachedBaseUrl != null) return _cachedBaseUrl!;
    final prefs = await SharedPreferences.getInstance();

    // If an explicit --dart-define=API_BASE_URL was supplied at build/run time,
    // ensure it overrides previously cached endpoints if it changed or was never recorded.
    if (_buildBaseUrl.isNotEmpty) {
      final lastBuild = prefs.getString(_lastDartDefineKey);
      if (lastBuild != _buildBaseUrl) {
        final cleaned = normalizeUrl(_buildBaseUrl);
        await prefs.setString(_serverUrlKey, cleaned);
        await prefs.setString(_lastDartDefineKey, _buildBaseUrl);
        _cachedBaseUrl = cleaned;
        return cleaned;
      }
    }

    var saved = prefs.getString(_serverUrlKey);
    // If the device has the old stale fallback saved from previous test runs, update to new LAN IP
    if (saved != null && saved.contains(_staleLanIp)) {
      saved = saved.replaceAll(_staleLanIp, _defaultLanIp);
      await prefs.setString(_serverUrlKey, saved);
    }

    _cachedBaseUrl = saved != null ? normalizeUrl(saved) : defaultBaseUrl;
    return _cachedBaseUrl!;
  }

  Future<void> setBaseUrl(String url) async {
    final cleaned = normalizeUrl(url);
    _cachedBaseUrl = cleaned;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, cleaned);
  }

  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
    return _cachedToken;
  }

  Future<void> saveToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  Future<void> saveUserJson(Map<String, dynamic> userJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userJson));
  }

  Future<Map<String, dynamic>?> getSavedUserJson() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, String>> _headers() async {
    final token = await getToken();
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      // Skips the ngrok free-plan warning page when the API is reached through ngrok.
      'ngrok-skip-browser-warning': 'true',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _buildUri(String path, String currentBaseUrl, [Map<String, dynamic>? queryParams]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final full = '$currentBaseUrl$cleanPath';
    final uri = Uri.parse(full);
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())));
    }
    return uri;
  }

  Future<ApiResponse> get(String path, {Map<String, dynamic>? query}) async {
    try {
      final base = await baseUrl;
      final uri = _buildUri(path, base, query);
      final headers = await _headers();
      final res = await http.get(uri, headers: headers).timeout(_timeout);
      return _parseResponse(res);
    } catch (e) {
      return ApiResponse(
        statusCode: 0,
        data: null,
        isSuccess: false,
        message: 'Network error: $e',
      );
    }
  }

  Future<ApiResponse> post(String path, {Map<String, dynamic>? body}) async {
    try {
      final base = await baseUrl;
      final uri = _buildUri(path, base);
      final headers = await _headers();
      final res = await http
          .post(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
          .timeout(_timeout);
      return _parseResponse(res);
    } catch (e) {
      return ApiResponse(
        statusCode: 0,
        data: null,
        isSuccess: false,
        message: 'Network error: $e',
      );
    }
  }

  Future<ApiResponse> put(String path, {Map<String, dynamic>? body}) async {
    try {
      final base = await baseUrl;
      final uri = _buildUri(path, base);
      final headers = await _headers();
      final res = await http
          .put(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
          .timeout(_timeout);
      return _parseResponse(res);
    } catch (e) {
      return ApiResponse(
        statusCode: 0,
        data: null,
        isSuccess: false,
        message: 'Network error: $e',
      );
    }
  }

  /// Uploads one file as multipart/form-data (e.g. a profile photo).
  Future<ApiResponse> postFile(
    String path, {
    required String field,
    required List<int> bytes,
    required String fileName,
  }) async {
    try {
      final base = await baseUrl;
      final request = http.MultipartRequest('POST', _buildUri(path, base));
      final headers = await _headers();
      headers.remove('Content-Type');
      request.headers.addAll(headers);
      request.files.add(http.MultipartFile.fromBytes(field, bytes, filename: fileName));
      final streamed = await request.send().timeout(const Duration(seconds: 30));
      return _parseResponse(await http.Response.fromStream(streamed));
    } catch (e) {
      return ApiResponse(
        statusCode: 0,
        data: null,
        isSuccess: false,
        message: 'Network error: $e',
      );
    }
  }

  /// Friendly message for a failed [ApiResponse].
  String errorMessage(ApiResponse res, String fallback) {
    if (res.statusCode == 0) {
      return 'Cannot reach the server. Check your connection and the server address.';
    }
    if (res.statusCode == 401) {
      return 'Your session has expired. Please log in again.';
    }
    return res.message ?? fallback;
  }

  /// Throws an [ApiException] for a failed [ApiResponse].
  Never fail(ApiResponse res, String fallback) =>
      throw ApiException(errorMessage(res, fallback), statusCode: res.statusCode);

  /// The `data` list of a Laravel resource collection response.
  static List<Map<String, dynamic>> dataList(dynamic body) {
    final list = body is Map && body.containsKey('data') ? body['data'] : body;
    if (list is! List) return const [];
    return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// A single resource from a response: `{data: {...}}`, `{<key>: {...}}`, or the body itself.
  static Map<String, dynamic>? dataItem(dynamic body, [String? key]) {
    if (body is! Map) return null;
    final item = body['data'] ?? (key != null ? body[key] : null) ?? body;
    return item is Map ? Map<String, dynamic>.from(item) : null;
  }

  ApiResponse _parseResponse(http.Response res) {
    dynamic decoded;
    try {
      decoded = jsonDecode(res.body);
    } catch (_) {
      decoded = res.body;
    }

    final isSuccess = res.statusCode >= 200 && res.statusCode < 300;
    String? message;
    if (decoded is Map) {
      message = decoded['message']?.toString();
      if (message == null && decoded['errors'] != null && decoded['errors'] is Map) {
        final errors = decoded['errors'] as Map;
        if (errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) {
            message = first.first.toString();
          }
        }
      }
    }

    return ApiResponse(
      statusCode: res.statusCode,
      data: decoded,
      isSuccess: isSuccess,
      message: message,
    );
  }
}
