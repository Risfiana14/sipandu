// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Impor Firebase Auth
import 'package:sipandu/screens/login_screen.dart';
import 'package:sipandu/services/auth_service.dart'; // Impor AuthService Firebase baru

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  
  final AuthService _authService = AuthService(); // Membuat instance dari AuthService Firebase
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = 'Ada kesalahan pada input. Periksa field di bawah.';
      });
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Password dan konfirmasi password tidak sama';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Memanggil fungsi register Firebase bawaan dari auth_service.dart
      User? user = await _authService.registerWithEmailAndPassword(
        emailController.text.trim(),
        passwordController.text,
        {
          'name': nameController.text.trim(),
          'role': 'user', // Otomatis mendaftarkan sebagai role standar 'user'
        },
      );

      if (user != null) {
        if (!mounted) return;
        // Pindah ke Halaman Login setelah berhasil mendaftar
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(fromRegister: true),
          ),
        );
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Registrasi gagal. Pastikan data benar atau email belum terdaftar.';
        });
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.code == 'email-already-in-use') {
          _errorMessage = 'Email tersebut sudah terdaftar.';
        } else if (e.code == 'invalid-email') {
          _errorMessage = 'Format penulisan email salah.';
        } else {
          _errorMessage = e.message ?? 'Terjadi kesalahan sistem Auth.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Terjadi kesalahan jaringan atau server. Silakan coba lagi nanti.';
      });
      print('Registration error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username tidak boleh kosong';
    }
    if (value.length < 3) {
      return 'Username minimal 3 karakter';
    }
    if (value.length > 20) {
      return 'Username maksimal 20 karakter';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Username hanya boleh mengandung huruf, angka, dan underscore';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    if (value.contains(' ')) {
      return 'Email tidak boleh mengandung spasi';
    }
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(value)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 8) {
      return 'Password minimal 8 karakter';
    }
    if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(value)) {
      return 'Password harus mengandung huruf dan angka';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password tidak boleh kosong';
    }
    if (value != passwordController.text) {
      return 'Password tidak sama';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
            decoration: const BoxDecoration(color: Colors.blue),
            child: const Column(
              children: [
                Text(
                  'WELCOME SIPANDU',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Aplikasi Sistem Pelayanan Terpadu',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
          // Form
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Register Icon and Title
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        child: const Column(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.black,
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'REGISTER',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 20),
                      // Error message
                      if (_errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Username Field
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          filled: true,
                          fillColor: Color(0xFFE3F2FD),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                          errorMaxLines: 2,
                        ),
                        validator: _validateUsername,
                        onChanged: (value) {
                          if (_errorMessage != null) {
                            setState(() {
                              _errorMessage = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      // Email Field
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          filled: true,
                          fillColor: Color(0xFFE3F2FD),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email_outlined),
                          errorMaxLines: 2,
                        ),
                        validator: _validateEmail,
                        onChanged: (value) {
                          if (_errorMessage != null) {
                            setState(() {
                              _errorMessage = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      // Password Field
                      TextFormField(
                        controller: passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          filled: true,
                          fillColor: const Color(0xFFE3F2FD),
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          errorMaxLines: 3,
                        ),
                        validator: _validatePassword,
                        onChanged: (value) {
                          if (_errorMessage != null) {
                            setState(() {
                              _errorMessage = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      // Confirm Password Field
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          filled: true,
                          fillColor: const Color(0xFFE3F2FD),
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                          errorMaxLines: 2,
                        ),
                        validator: _validateConfirmPassword,
                        onChanged: (value) {
                          if (_errorMessage != null) {
                            setState(() {
                              _errorMessage = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      // Register Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            elevation: _isLoading ? 0 : 2,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'REGISTER',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Login Link
                      TextButton(
                        onPressed:
                            _isLoading ? null : () => Navigator.pop(context),
                        child: const Text(
                          "Already have an account? Login",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}