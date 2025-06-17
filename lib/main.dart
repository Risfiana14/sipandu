import 'package:flutter/material.dart';
import 'package:sipandu/screens/splash_screen.dart';
import 'package:sipandu/screens/login_screen.dart';
import 'package:sipandu/screens/register_screen.dart';
// import 'package:sipandu/screens/profile_screen.dart'; // Unused import - commented out or remove

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sipandu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          secondary: Colors.green,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          titleTextStyle: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        // Pass fromRegister: false as it's not coming from registration directly
        '/login': (context) => const LoginScreen(fromRegister: false),
        '/register': (context) => const RegisterScreen(),
        // '/profile': (context) => const ProfileScreen(), // Uncomment if you use this route
      },
    );
  }
}
