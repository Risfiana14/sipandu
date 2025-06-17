import 'package:pocketbase/pocketbase.dart';
import 'package:sipandu/models/user_profile.dart';
import 'pocketbase_client.dart';

class PocketBaseService {
  static final PocketBase _pb = PocketBaseClient.instance;

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('Attempting login at: $pocketBaseUrl');
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
      print('ClientException: ${e.response}');
      String errorMessage = 'Login failed. Please try again.';
      if (e.response['message'] != null) {
        errorMessage = e.response['message'];
      } else if (e.response['data'] != null) {
        final data = e.response['data'] as Map<String, dynamic>;
        if (data.containsKey('email') && data['email']['message'] != null) {
          errorMessage = 'Email: ${data['email']['message']}';
        }
      }
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('Unexpected error: $e');
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
      print('Attempting registration at: $pocketBaseUrl');
      final userData = {
        'username': name,
        'email': email,
        'password': password,
        'passwordConfirm': password,
      };

      final record = await _pb.collection('users').create(body: userData);
      print('Registration successful. Response: ${record.toJson()}');

      return {
        'success': true,
        'message': 'Registration successful',
        'data': record.toJson(),
      };
    } on ClientException catch (e) {
      print('ClientException: ${e.response}');
      String errorMessage = 'Registration failed. Please try again.';
      if (e.response['message'] != null) {
        errorMessage = e.response['message'];
      } else if (e.response['data'] != null) {
        final data = e.response['data'] as Map<String, dynamic>;
        if (data.containsKey('email') && data['email']['message'] != null) {
          errorMessage = 'Email: ${data['email']['message']}';
        } else if (data.containsKey('username') &&
            data['username']['message'] != null) {
          errorMessage = 'Username: ${data['username']['message']}';
        }
      }
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('Unexpected error: $e');
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
      if (!_pb.authStore.isValid) return null;
      final record =
          await _pb.collection('users').getOne(_pb.authStore.model.id);
      print('Fetched user record: ${record.data}');
      return UserProfile.fromJson(record.data);
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  static void clearAuthStore() {
    _pb.authStore.clear();
  }
}
