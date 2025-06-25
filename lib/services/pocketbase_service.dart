// lib/services/pocketbase_service.dart
import 'package:pocketbase/pocketbase.dart';
import 'package:sipandu/models/user_profile.dart';
import 'pocketbase_client.dart'; // Assuming this provides PocketBaseClient.instance and pocketBaseUrl

class PocketBaseService {
  static final PocketBase _pb = PocketBaseClient.instance;

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print(
          'Attempting login at: $pocketBaseUrl'); // pocketBaseUrl from pocketbase_client.dart
      final authData =
          await _pb.collection('users').authWithPassword(email, password);
      _pb.authStore.save(authData.token, authData.record);
      print(
          'Login successful, token: ${_pb.authStore.token}, isValid: ${_pb.authStore.isValid}');

      // Verify session immediately after login
      final user = await getCurrentUser();
      if (user == null) {
        throw Exception('Session validation failed after login');
      }

      return {
        'success': true,
        'message': 'Login successful',
        'data': authData.toJson(),
      };
    } on ClientException catch (e) {
      print('ClientException during login: ${e.response}');
      String errorMessage = 'Login failed. Please check your credentials.';

      // Attempt to get more specific error from PocketBase response
      if (e.response.containsKey('message') &&
          e.response['message'] is String) {
        errorMessage = e.response['message'];
      } else if (e.response.containsKey('data') && e.response['data'] is Map) {
        final data = e.response['data'] as Map<String, dynamic>;
        if (data.containsKey('email') &&
            data['email'] is Map &&
            data['email'].containsKey('message')) {
          errorMessage = 'Email: ${data['email']['message']}';
        } else if (data.containsKey('password') &&
            data['password'] is Map &&
            data['password'].containsKey('message')) {
          errorMessage = 'Password: ${data['password']['message']}';
        }
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('Unexpected error during login: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      print(
          'Attempting registration at: $pocketBaseUrl'); // pocketBaseUrl from pocketbase_client.dart
      final userData = {
        'username': name,
        'email': email,
        'password': password,
        'passwordConfirm': password, // Required by PocketBase for registration
        'name': name, // Store the display name
        'role': 'user', // <--- AUTOMATICALLY SET ROLE HERE
      };

      final record = await _pb.collection('users').create(body: userData);
      print('Registration successful. Response: ${record.toJson()}');

      return {
        'success': true,
        'message': 'Registration successful',
        'data': record.toJson(),
      };
    } on ClientException catch (e) {
      print('ClientException during registration: ${e.response}');
      String errorMessage = 'Registration failed. Please try again.';

      // Attempt to get more specific error from PocketBase response
      if (e.response.containsKey('message') &&
          e.response['message'] is String) {
        errorMessage = e.response['message'];
      } else if (e.response.containsKey('data') && e.response['data'] is Map) {
        final data = e.response['data'] as Map<String, dynamic>;
        if (data.containsKey('email') &&
            data['email'] is Map &&
            data['email'].containsKey('message')) {
          errorMessage = 'Email: ${data['email']['message']}';
        } else if (data.containsKey('username') &&
            data['username'] is Map &&
            data['username'].containsKey('message')) {
          errorMessage = 'Username: ${data['username']['message']}';
        } else if (data.containsKey('password') &&
            data['password'] is Map &&
            data['password'].containsKey('message')) {
          errorMessage = 'Password: ${data['password']['message']}';
        }
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('Unexpected error during registration: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  static Future<UserProfile?> getCurrentUser() async {
    try {
      print(
          'Auth store is valid: ${_pb.authStore.isValid}, token: ${_pb.authStore.token}');
      if (!_pb.authStore.isValid) {
        print('Auth store is not valid. Returning null.');
        return null;
      }

      // Check if model is not null and has an ID
      if (_pb.authStore.model == null || _pb.authStore.model!.id.isEmpty) {
        print('Auth store model is null or has no ID. Returning null.');
        return null;
      }

      final record =
          await _pb.collection('users').getOne(_pb.authStore.model!.id);
      print('Fetched user record: ${record.data}');
      return UserProfile.fromJson(record.data);
    } on ClientException catch (e) {
      print('ClientException fetching user profile: ${e.response}');
      // This might happen if the token is expired or invalid server-side
      clearAuthStore(); // Clear invalid session
      return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  static void clearAuthStore() {
    print('Clearing PocketBase auth store.');
    _pb.authStore.clear();
  }
}