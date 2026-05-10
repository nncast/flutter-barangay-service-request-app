import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // OPTION 1: For Android Emulator
  // static const String baseUrl = 'http://10.0.2.2:8000/api';

  // OPTION 2: For Windows Desktop (default)
  static const String baseUrl = 'http://localhost:8000/api';

  // OPTION 3: For Physical Device (find your IP using 'ipconfig')
  // static const String baseUrl = 'http://192.168.1.100:8000/api';

  // OPTION 4: For Web
  // static const String baseUrl = 'http://127.0.0.1:8000/api';

  // Timeout duration for requests (30 seconds)
  static const Duration timeoutDuration = Duration(seconds: 30);

  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
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

  static Future<http.Response> get(String endpoint, {bool auth = true}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      print('GET Request: $uri');

      final response = await http
          .get(
        uri,
        headers: await _headers(auth: auth),
      )
          .timeout(timeoutDuration);

      print('GET Response Status: ${response.statusCode}');
      return response;
    } catch (e) {
      print('GET Error: $e');
      rethrow;
    }
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body,
      {bool auth = true}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      print('POST Request: $uri');
      print('POST Body: $body');

      final response = await http
          .post(
        uri,
        headers: await _headers(auth: auth),
        body: jsonEncode(body),
      )
          .timeout(timeoutDuration);

      print('POST Response Status: ${response.statusCode}');
      print('POST Response Body: ${response.body}');
      return response;
    } catch (e) {
      print('POST Error: $e');
      rethrow;
    }
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> body,
      {bool auth = true}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      print('PUT Request: $uri');

      final response = await http
          .put(
        uri,
        headers: await _headers(auth: auth),
        body: jsonEncode(body),
      )
          .timeout(timeoutDuration);

      print('PUT Response Status: ${response.statusCode}');
      return response;
    } catch (e) {
      print('PUT Error: $e');
      rethrow;
    }
  }

  static Future<http.Response> delete(String endpoint, {bool auth = true}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      print('DELETE Request: $uri');

      final response = await http
          .delete(
        uri,
        headers: await _headers(auth: auth),
      )
          .timeout(timeoutDuration);

      print('DELETE Response Status: ${response.statusCode}');
      return response;
    } catch (e) {
      print('DELETE Error: $e');
      rethrow;
    }
  }

  // Helper method to test connection
  static Future<bool> testConnection() async {
    try {
      final response = await get('/categories', auth: false);
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
}