import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// Impor berkas SplashScreen asli Anda
import 'package:sipandu/screens/splash_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    // Konfigurasi Firebase khusus platform Web/Chrome agar tidak memicu error null
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyYourAPIKeyHere_SalinDariFirebaseConsole",
        appId: "1:your:web:appId",
        messagingSenderId: "your_sender_id",
        projectId: "sipandu",
        storageBucket: "sipandu.appspot.com",
      ),
    );
  } else {
    // Konfigurasi otomatis untuk Android (Membaca berkas google-services.json)
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SiPandu',
      debugShowCheckedModeBanner: false, // Menghilangkan pita DEBUG di pojok kanan atas
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // KEMBALIKAN KE SCREEN AWAL ASLI ANDA
      home: const SplashScreen(), 
    );
  }
}