import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_text_styles.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/scaleflow_logo.dart';

/// شاشة تسجيل الدخول (Login Screen)
/// نفس التنسيق والألوان المعتمدة: عنوان، حقلي إيميل وكلمة سر،
/// رابط نسيت كلمة السر، زر تسجيل الدخول، ورابط إنشاء حساب جديد
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(value);
  }

  void _validateEmail(String value) {
    setState(() {
      if (value.isEmpty) {
        _emailError = null;
      } else if (!_isValidEmail(value)) {
        _emailError = 'Please enter a valid email address';
      } else {
        _emailError = null;
      }
    });
  }

  void _handleLogin() {
    setState(() {
      _emailError = _emailController.text.isEmpty
          ? 'This field is required'
          : (!_isValidEmail(_emailController.text)
              ? 'Please enter a valid email address'
              : null);
      _passwordError =
          _passwordController.text.isEmpty ? 'This field is required' : null;
    });

    if (_emailError == null && _passwordError == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged in successfully ✅')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Directionality صريحة LTR هون كطبقة حماية إضافية، فوق الفرض العام
    // بـ main.dart، حتى تتأكد إنو الحقول بتشتغل صح مهما كانت لغة الجهاز.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxContentWidth = constraints.maxWidth < 500
                ? constraints.maxWidth
                : 420.0;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: ScaleFlowLogo()),
                      const SizedBox(height: 24),
                      Text('Welcome back',
                          style: AppTextStyles.heading,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 6),
                      Text('Manage your projects smarter.',
                          style: AppTextStyles.subtitle,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 32),

                      CustomTextField(
                        label: 'Email Address',
                        hint: 'Enter your email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        errorText: _emailError,
                        onChanged: _validateEmail,
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        label: 'Password',
                        hint: 'Enter your password',
                        controller: _passwordController,
                        isPassword: true,
                        errorText: _passwordError,
                        onChanged: (_) {
                          if (_passwordError != null) {
                            setState(() => _passwordError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 10),

                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            Navigator.of(context)
                                .pushNamed('/forgot-password');
                          },
                          child: Padding(
                            // padding كافي حتى منطقة الضغط تكون واضحة
                            // ومش بس النص نفسه (سهّل الضغط عليها)
                            padding: const EdgeInsets.symmetric(
                                vertical: 6, horizontal: 2),
                            child: Text('Forgot password?',
                                style: AppTextStyles.forgotPassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryButton,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: Text('Log In', style: AppTextStyles.buttonText),
                        ),
                      ),
                      const SizedBox(height: 40),

                      Center(
                        child: RichText(
                          text: TextSpan(
                            style: AppTextStyles.footerText,
                            children: [
                              const TextSpan(text: "Don't have an account? "),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context)
                                        .pushReplacementNamed('/register');
                                  },
                                  child: Text('Create one',
                                      style: AppTextStyles.footerLink),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      ),
    );
  }
}
