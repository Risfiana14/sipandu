// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:sipandu/screens/home_screen.dart';
import 'package:sipandu/screens/dashboard_admin_screen.dart';
import 'package:sipandu/services/pocketbase_client.dart';
import 'package:sipandu/screens/register_screen.dart';

class LoginScreen extends StatefulWidget {
  // Make fromRegister optional with a default value
  final bool fromRegister;
  const LoginScreen({super.key, this.fromRegister = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final PocketBase _pb = PocketBaseClient.instance;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // If we came from registration, show a success message
    if (widget.fromRegister) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrasi berhasil! Silakan login.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      });
    }
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authData = await _pb.collection('users').authWithPassword(
            _emailController.text,
            _passwordController.text,
          );

      final RecordModel? userRecord = _pb.authStore.model;

      if (userRecord != null && userRecord.data['role'] != null) {
        final userRole = userRecord.data['role'] as String;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login berhasil sebagai $userRole')),
        );

        if (userRole == 'admin') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const DashboardAdminScreen(),
            ),
          );
        } else if (userRole == 'user') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => HomeScreen(userData: userRecord.data),
            ),
          );
        } else {
          setState(() {
            _errorMessage =
                'Peran pengguna tidak dikenal. Silakan hubungi administrator.';
          });
          _pb.authStore.clear();
        }
      } else {
        setState(() {
          _errorMessage =
              'Gagal mendapatkan data peran pengguna. Silakan coba lagi.';
        });
        _pb.authStore.clear();
      }
    } on ClientException catch (e) {
      String message = 'Terjadi kesalahan saat login.';
      if (e.response.containsKey('message')) {
        message = e.response['message'] as String;
      } else if (e.response.containsKey('data') && e.response['data'] is Map) {
        final data = e.response['data'] as Map<String, dynamic>;
        if (data.containsKey('identity') && data['identity'] is Map) {
          message = data['identity']['message'] as String? ?? message;
        } else if (data.containsKey('password') && data['password'] is Map) {
          message = data['password']['message'] as String? ?? message;
        }
      }
      setState(() {
        _errorMessage = message;
      });
      print(
          'Login error (ClientException): ${e.response}'); // Consider using a proper logger
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan tidak terduga: $e';
      });
      print('Unexpected login error: $e'); // Consider using a proper logger
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.supervised_user_circle,
                size: 100,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 32),
              Text(
                'Selamat Datang Kembali!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Silakan login untuk melanjutkan',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) =>
                            const RegisterScreen()), // Menggunakan RegisterScreen
                  );
                },
                child: Text(
                  'Belum punya akun? Daftar di sini',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
