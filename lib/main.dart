// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:sipandu/screens/login_screen.dart';
import 'package:sipandu/screens/home_screen.dart';
import 'package:sipandu/screens/dashboard_admin_screen.dart';
import 'package:sipandu/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inisialisasi Firebase menggunakan konfigurasi
    // yang dibuat oleh FlutterFire CLI
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Firebase Initialization Error: $e");
  }

  runApp(const SipanduApp());
}

class SipanduApp extends StatelessWidget {
  const SipanduApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sipandu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.blue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          primary: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Dipastikan instansiasi service dipanggil dengan benar jika dibutuhkan nanti
    final AuthService authService = AuthService();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Tangani error pada stream utama auth
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text(
                "Terjadi kesalahan pada sistem Autentikasi.",
              ),
            ),
          );
        }

        // 2. Jika sedang loading koneksi ke Firebase Auth
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // 3. Jika user sudah login sebelumnya
        if (snapshot.hasData && snapshot.data != null) {
          User user = snapshot.data!;

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get(),
            builder: (context, userSnapshot) {
              // PERBAIKAN: Tangani error jika Firestore gagal mengambil data
              if (userSnapshot.hasError) {
                print("Firestore Error: ${userSnapshot.error}");

                return Scaffold(
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Gagal memuat data pengguna: ${userSnapshot.error}",
                      ),
                    ),
                  ),
                );
              }

              // Jika data dokumen dari database masih dimuat
              if (userSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // Jika data sukses didapatkan dan dokumennya terdaftar di Firestore
              if (userSnapshot.hasData &&
                  userSnapshot.data!.exists) {
                Map<String, dynamic> userData =
                    userSnapshot.data!.data()
                        as Map<String, dynamic>;

                String role = userData['role'] ?? 'user';

                if (role == 'admin') {
                  return const DashboardAdminScreen();
                } else {
                  return HomeScreen(userData: userData);
                }
              }

              // Jika akun terautentikasi di Auth tapi data dokumen
              // di Firestore kosong/dihapus
              return const LoginScreen();
            },
          );
        }

        // Jika belum login, arahkan langsung ke LoginScreen
        return const LoginScreen();
      },
    );
  }
}