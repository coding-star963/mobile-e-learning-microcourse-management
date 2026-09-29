import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  // Default server address:
  // On Edge/Web -> http://127.0.0.1:8000/api
  // On physical mobile -> http://192.168.8.56:8000/api (local Wi-Fi LAN IP)
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }
    return 'http://192.168.8.56:8000/api';
  }

  String? _cachedBaseUrl;
  String? _cachedToken;

  Future<String> get baseUrl async {
    if (_cachedBaseUrl != null) return _cachedBaseUrl!;
    final prefs = await SharedPreferences.getInstance();
    _cachedBaseUrl = prefs.getString(_serverUrlKey) ?? defaultBaseUrl;
    return _cachedBaseUrl!;
  }

  Future<void> setBaseUrl(String url) async {
    var cleaned = url.trim();
    if (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    if (!cleaned.endsWith('/api')) {
      cleaned = '$cleaned/api';
    }
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
      final res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 8));
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
          .timeout(const Duration(seconds: 8));
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
          .timeout(const Duration(seconds: 8));
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
