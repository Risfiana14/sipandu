import 'package:pocketbase/pocketbase.dart';

const String pocketBaseUrl = 'http://127.0.0.1:8090';

class AuthService {
  static final PocketBase _pb = PocketBase(pocketBaseUrl);

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
}
