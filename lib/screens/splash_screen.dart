import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:sipandu/screens/home_screen.dart';
import 'package:sipandu/screens/login_screen.dart';
import 'package:sipandu/services/pocketbase_client.dart'; // Ensure this is imported

class AuthService {

  static final PocketBase _pb = PocketBaseClient.instance;

  static Future<bool> isLoggedIn() async {
    try {
      await _pb.collection('users').authRefresh();
      return _pb.authStore.isValid;
    } on ClientException catch (e) {
      // Catch PocketBase specific exceptions (e.g., 401 Unauthorized)
      print('Auth refresh client error: ${e.response}');
      return false;
    } catch (e) {
      print('Auth check error: $e'); // General error
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (_pb.authStore.isValid && _pb.authStore.model != null) {
        final record =
            await _pb.collection('users').getOne(_pb.authStore.model.id);
        print('Fetched user record: ${record.data}');
        return record.data;
      }
      return null;
    } on ClientException catch (e) {
      print('Error fetching user data (ClientException): ${e.response}');
      return null;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2)); // Splash screen delay

    final isLoggedIn = await AuthService.isLoggedIn();

    if (mounted) {
      if (isLoggedIn) {
        final userData = await AuthService.getUserData();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
                userData: userData ?? {}), // Sediakan userData atau map kosong
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            // Corrected: Pass the 'fromRegister' parameter to LoginScreen
            builder: (context) => const LoginScreen(fromRegister: false),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.blue,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_balance,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            const Text(
              'SIPANDU',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Aplikasi Sistem Pelayanan Terpadu',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
