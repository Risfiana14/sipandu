import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth menggantikan PocketBase
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore untuk ambil data pengguna
import 'package:sipandu/screens/home_screen.dart';
import 'package:sipandu/screens/login_screen.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Cek apakah pengguna sudah memiliki sesi login aktif di Firebase
  static Future<bool> isLoggedIn() async {
    try {
      final User? currentUser = _auth.currentUser;
      return currentUser != null;
    } catch (e) {
      print('Auth check error: $e'); 
      return false;
    }
  }

  // Mengambil data pengguna dari Firestore berdasarkan UID saat ini
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc = await _db.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          data['uid'] = userDoc.id; // Menyisipkan UID dokumen Firestore
          print('Fetched user record: $data');
          return data;
        }
      }
      return null;
    } catch (e) {
      print('Error fetching user data from Firestore: $e');
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

    final bool loggedIn = await AuthService.isLoggedIn();

    if (mounted) {
      if (loggedIn) {
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
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            Text(
              'SIPANDU',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Aplikasi Sistem Pelayanan Terpadu',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}