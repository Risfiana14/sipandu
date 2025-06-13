import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sipandu/models/user_profile.dart';

class AuthService {
  // Ganti dengan URL API Laravel Anda
  static const String baseUrl = "http://127.0.0.1:8000/api"; // URL API Laravel

  // Token key
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // Get stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  // Save token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  // Save user data
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userKey, json.encode(userData));
  }

  // Get user data
  static Future<UserProfile?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(userKey);

    if (userData == null) return null;

    try {
      final Map<String, dynamic> userMap = json.decode(userData);
      return UserProfile.fromJson(userMap);
    } catch (e) {
      print('Error parsing user data: $e');
      return null;
    }
  }

  // Remove auth data
  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(userKey);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // Get headers with token
  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Register user - Updated to use the specified API endpoint
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      print('Sending registration request to: $baseUrl/register');

      final response = await http.post(
        Uri.parse("$baseUrl/register"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'confirm_password': password, // Updated from password_confirmation
        }),
      );

      print('Registration response status: ${response.statusCode}');
      print('Registration response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Check if token is available in response
        if (data['data']['token'] != null) {
          await saveToken(data['data']['token']);
        }

        // Check if user data is available in response
        if (data['data']['name'] != null) {
          await saveUserData({'name': data['data']['name']});
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Registration successful',
          'user': data['data'],
        };
      } else {
        // Handle validation errors or other error responses
        String errorMessage = 'Registration failed';

        if (data['message'] != null) {
          errorMessage = data['message'];
        } else if (data['errors'] != null) {
          // Laravel validation errors format
          final errors = data['errors'] as Map<String, dynamic>;
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            errorMessage = firstError.first.toString();
          }
        }

        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      print('Registration error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Login user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (data['token'] != null) {
          await saveToken(data['token']);
        }

        if (data['user'] != null) {
          await saveUserData(data['user']);
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Login successful',
          'user': data['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Invalid credentials',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Logout user
  static Future<Map<String, dynamic>> logout() async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/logout"),
        headers: await getHeaders(),
      );

      await clearAuthData();
      return json.decode(response.body);
    } catch (e) {
      await clearAuthData();
      return {
        'success': true,
        'message': 'Logged out locally',
      };
    }
  }

  // Get user profile
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/user"),
        headers: await getHeaders(),
      );

      final data = json.decode(response.body);

      if (data['success'] && data['user'] != null) {
        await saveUserData(data['user']);
      }

      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateUserProfile({
    required String name,
    String? phone,
    String? address,
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/user"),
        headers: await getHeaders(),
        body: json.encode({
          'name': name,
          'phone': phone,
          'address': address,
        }),
      );

      final data = json.decode(response.body);

      if (data['success'] && data['user'] != null) {
        await saveUserData(data['user']);
      }

      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}
