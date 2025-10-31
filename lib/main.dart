// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart'; // Still needed for navigation
import 'widgets/main_navigator.dart';
import 'services/user_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (context) => UserState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Currency Converter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
         colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0D47A1),
              primary: const Color(0xFF0D47A1),
              secondary: const Color(0xFF4CAF50),
              background: const Color(0xFFF5F5F5),
              onPrimary: Colors.white,
            ),
            textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
              filled: true,
              fillColor: Colors.white,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            useMaterial3: true,
      ),
      home: Consumer<UserState>(
        builder: (context, userState, child) {
          if (userState.isLoading) {
             return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
             );
          }
          // ALWAYS show MainNavigator. It will handle guest/user state.
          return const MainNavigator();
        },
      ),
      // Route for LoginScreen
      routes: {
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}