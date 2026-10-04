import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  /// Base URL of the Laravel API.
  ///
  /// Defaults to the Android emulator's alias for the host machine
  /// (`10.0.2.2`) on Android and to `localhost` everywhere else. For a
  /// physical phone, pass your computer's LAN address at build time:
  ///
  ///   flutter run --dart-define=API_BASE_URL=http://192.168.1.100:8000/api
  static final String baseUrl = _resolveBaseUrl();

  static String _resolveBaseUrl() {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://localhost:8000/api';
  }

  static const Duration timeoutDuration = Duration(seconds: 30);
  static const String _tokenKey = 'auth_token';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // Only the method, path and status are logged — never bodies, which can
  // contain passwords and tokens.
  static void _log(String method, Uri uri, [int? status]) {
    if (kDebugMode) {
      debugPrint('$method ${uri.path}${status != null ? ' -> $status' : ''}');
    }
  }

  static Future<http.Response> get(String endpoint, {bool auth = true}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http
        .get(uri, headers: await _headers(auth: auth))
        .timeout(timeoutDuration);
    _log('GET', uri, response.statusCode);
    return response;
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body,
      {bool auth = true}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http
        .post(uri, headers: await _headers(auth: auth), body: jsonEncode(body))
        .timeout(timeoutDuration);
    _log('POST', uri, response.statusCode);
    return response;
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> body,
      {bool auth = true}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http
        .put(uri, headers: await _headers(auth: auth), body: jsonEncode(body))
        .timeout(timeoutDuration);
    _log('PUT', uri, response.statusCode);
    return response;
  }

  static Future<http.Response> delete(String endpoint, {bool auth = true}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http
        .delete(uri, headers: await _headers(auth: auth))
        .timeout(timeoutDuration);
    _log('DELETE', uri, response.statusCode);
    return response;
  }

  /// Pulls a readable message out of a Laravel error response:
  /// the first validation error if there is one, otherwise `message`.
  static String errorMessage(http.Response res, String fallback) {
    try {
      final body = jsonDecode(res.body);
      if (body is Map) {
        final errors = body['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
          return first.toString();
        }
        final message = body['message'];
        if (message is String && message.isNotEmpty) return message;
      }
    } catch (_) {}
    if (res.statusCode == 429) return 'Too many attempts. Please wait a minute and try again.';
    return fallback;
  }
}
