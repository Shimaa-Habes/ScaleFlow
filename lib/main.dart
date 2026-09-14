import 'package:flutter/material.dart';
import 'core/app_colors.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';

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
        fontFamily: 'Roboto', // بدّلها بخط الهوية البصرية الرسمي إذا متوفر
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryButton,
        ),
      ),
      // نفرض اللغة الإنجليزية + اتجاه LTR على كامل التطبيق، بغض النظر عن
      // لغة الجهاز/المتصفح. هاد بيمنع مشكلة إنو Flutter يحوّل التطبيق
      // تلقائياً لـ RTL (لما يكون locale الجهاز عربي)، وهاد كان سبب
      // مشكلة الـ backspace/الحذف اللي ما عم تشتغل مزبوط جوا الحقول.
      locale: const Locale('en', 'US'),
      supportedLocales: const [Locale('en', 'US')],
      initialRoute: '/register',
      routes: {
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
      },
    );
  }
}
