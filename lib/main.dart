import 'package:flutter/material.dart';

import 'core/app_colors.dart';

import 'screens/global.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ScaleFlowApp());
}

class ScaleFlowApp extends StatelessWidget {
  const ScaleFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScaleFlow',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryButton,
        ),
      ),

      // ------------------------------------------------------
      // Force English + LTR
      // ------------------------------------------------------

      locale: const Locale('en', 'US'),

      supportedLocales: const [
        Locale('en', 'US'),
      ],

      // ------------------------------------------------------
      // ScaleFlow Flow
      //
      // Global
      //   ↓
      // Login
      //   ↓
      // Register
      //   ↓
      // Home
      // ------------------------------------------------------

      initialRoute: '/global',

      routes: {
        // 1. Global / Welcome
        '/global': (context) => const GlobalPage(),

        // 2. Login
        '/login': (context) => const LoginScreen(),

        // 3. Register
        '/register': (context) => const RegisterScreen(),

        // Forgot Password
        '/forgot-password': (context) => const ForgotPasswordScreen(),

        // 4. Home
        '/home': (context) => const HomePage(),
      },
    );
  }
}
