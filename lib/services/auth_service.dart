// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Login menggunakan Firebase Authentication (Dipanggil di login_screen.dart)
  Future<User?> loginWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      print('Login error: ${e.code} - ${e.message}');
      rethrow; // Dilempar agar bisa ditangkap oleh blok catch di login_screen.dart
    } catch (e) {
      print('Unexpected login error: $e');
      return null;
    }
  }

  /// Registrasi via Firebase Auth & Simpan Profile ke Firestore (Dipanggil di register_screen.dart)
  Future<User?> registerWithEmailAndPassword(
    String email,
    String password,
    Map<String, dynamic> extraData,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // Menyimpan data profile ke Firestore users collection
        await _db.collection('users').doc(user.uid).set({
          'email': email,
          ...extraData,
        });
      }
      return user;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      print('Unexpected registration error: $e');
      return null;
    }
  }

  /// Logout dari Firebase Auth
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Ambil data user Firebase yang sedang login saat ini
  User? get currentUser => _auth.currentUser;
}