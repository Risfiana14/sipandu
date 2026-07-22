// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'package:sipandu/screens/login_screen.dart';
import 'package:sipandu/screens/home_screen.dart';
import 'package:sipandu/screens/dashboard_admin_screen.dart';
import 'package:sipandu/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  // 1. Wajib ditambahkan agar inisialisasi asinkronus berjalan lancar
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 2. Inisialisasi Firebase dengan menyertakan opsi kredensial Web Chrome
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBkAm-6OZBPtRnNfc-SfMHtRYmItUcZ1jo",
        authDomain: "sipandu-ea21b.firebaseapp.com",
        projectId: "sipandu-ea21b",
        storageBucket: "sipandu-ea21b.firebasestorage.app",
        messagingSenderId: "741436438006",
        appId: "1:741436438006:web:3b15655bf43dc4b4be83d7",
        measurementId: "G-FZHD4K4PZD",
      ),
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
      // 3. Menggunakan StreamBuilder untuk mengecek status login pengguna secara realtime
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return StreamBuilder<User?>(
      // Memantau perubahan status login dari Firebase Auth
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Jika sedang loading koneksi ke Firebase Auth
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Jika user sudah login sebelumnya
        if (snapshot.hasData && snapshot.data != null) {
          User user = snapshot.data!;
          
          // Ambil data detail role user dari Firestore untuk menentukan halaman tujuan
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                Map<String, dynamic> userData = userSnapshot.data!.data() as Map<String, dynamic>;
                String role = userData['role'] ?? 'user';

                if (role == 'admin') {
                  return const DashboardAdminScreen();
                } else {
                  return HomeScreen(userData: userData);
                }
              }

              // Jika data dokumen di Firestore tidak ada, fallback ke Login
              return const LoginScreen();
            },
          );
        }

        // Jika belum login, arahkan ke LoginScreen
        return const LoginScreen();
      },
    );
  }
}