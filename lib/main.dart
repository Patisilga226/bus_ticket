import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'ui/pages/login_page.dart';

void main() {
  runApp(const BusAdminApp());
}

class BusAdminApp extends StatelessWidget {
  const BusAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4F46E5),
        background: const Color(0xFFF3F4FB),
      ),
      textTheme: GoogleFonts.poppinsTextTheme(),
    );

    return MaterialApp(
      title: 'Bus Admin Dashboard',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        scaffoldBackgroundColor: const Color(0xFFE5E7F5),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

