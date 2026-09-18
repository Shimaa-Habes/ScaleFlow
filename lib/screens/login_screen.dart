import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_text_styles.dart';
import '../data/mock_data.dart';
import '../widgets/custom_text_field.dart';

/// Login Screen
/// Contains the welcome message, email and password fields,
/// forgot password link, login button, and account creation link.
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

  // General login error shown when email or password is incorrect.
  // This avoids revealing whether the email address exists.
  String? _loginError;

  // ============================================================
  // TODO (Backend track):
  // CurrentUser.login() currently validates accounts stored in memory.
  // Replace this with a real POST /auth/login API endpoint later.
  // ============================================================

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

      _loginError = null;
    });

    if (_emailError != null || _passwordError != null) return;

    // Validate the entered credentials against the current mock accounts.
    // Replace this with a real API request when backend integration is ready.
    final isCorrect = CurrentUser.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!isCorrect) {
      setState(() => _loginError = 'Invalid email or password');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged in successfully ✅')),
    );

    // Navigate to the Home screen after successful login.
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Explicitly use LTR direction to ensure the fields and layout
    // remain consistent regardless of the device language.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Limit the content width on larger screens.
              final maxContentWidth =
                  constraints.maxWidth < 500 ? constraints.maxWidth : 420.0;

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    0,
                    24,
                    24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: maxContentWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Display the uploaded ScaleFlow logo asset.
                        Center(
                          child: Image.asset(
                            'assets/images/Logo.png',
                            width: 220,
                            fit: BoxFit.contain,
                          ),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          'Welcome back',
                          style: AppTextStyles.heading,
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 6),

                        Text(
                          'Manage your projects smarter.',
                          style: AppTextStyles.subtitle,
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 32),

                        CustomTextField(
                          label: 'Email Address',
                          hint: 'Enter your email',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          errorText: _emailError,
                          onChanged: (value) {
                            _validateEmail(value);

                            if (_loginError != null) {
                              setState(() => _loginError = null);
                            }
                          },
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

                            if (_loginError != null) {
                              setState(() => _loginError = null);
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
                              // Add enough padding to make the link
                              // easier to tap on smaller screens.
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 2,
                              ),
                              child: Text(
                                'Forgot password?',
                                style: AppTextStyles.forgotPassword,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        if (_loginError != null) ...[
                          Text(
                            _loginError!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                        ],

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
                            child: Text(
                              'Log In',
                              style: AppTextStyles.buttonText,
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        Center(
                          child: RichText(
                            text: TextSpan(
                              style: AppTextStyles.footerText,
                              children: [
                                const TextSpan(
                                  text: "Don't have an account? ",
                                ),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.of(context)
                                          .pushReplacementNamed('/register');
                                    },
                                    child: Text(
                                      'Create one',
                                      style: AppTextStyles.footerLink,
                                    ),
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
