import 'package:flutter/material.dart';
import 'dart:ui';

import '../core/app_colors.dart';
import '../core/app_text_styles.dart';
import '../services/auth_service.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  String? _emailError;
  String? _passwordError;
  String? _loginError;

  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _isLoading = false; 

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(value);
  }

  void _handleLogin() async {
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

    setState(() {
      _isLoading = true; 
    });

    final bool isSuccess = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() {
      _isLoading = false; 
    });

    if (!isSuccess) {
      setState(() => _loginError = 'Invalid email, password, or server error');
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged in successfully ✅')),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/Login-Image.jpg',
                fit: BoxFit.cover,
              ),
            ),

            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                child: Container(
                  color: Colors.white.withOpacity(0.35),
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),

                        // Logo
                        Center(
                          child: Image.asset(
                            'assets/images/Logo.png',
                            height: 90,
                            fit: BoxFit.contain,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Title
                        Text(
                          'Welcome Back',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.heading.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A1D26),
                            letterSpacing: 0.5,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          'Sign in to your account to continue',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.subtitle.copyWith(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Email
                        _buildLabel('Email Address'),
                        const SizedBox(height: 6),
                        _buildTextField(
                          controller: _emailController,
                          hint: 'you@company.com',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          errorText: _emailError,
                          onChanged: (_) {
                            if (_emailError != null || _loginError != null) {
                              setState(() {
                                _emailError = null;
                                _loginError = null;
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 18),

                        // Password
                        _buildLabel('Password'),
                        const SizedBox(height: 6),
                        _buildTextField(
                          controller: _passwordController,
                          hint: 'Enter your password',
                          prefixIcon: Icons.lock_outline_rounded,
                          isPassword: true,
                          errorText: _passwordError,
                          onChanged: (_) {
                            if (_passwordError != null || _loginError != null) {
                              setState(() {
                                _passwordError = null;
                                _loginError = null;
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 14),

                        // Remember me + Forgot password
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _rememberMe = !_rememberMe;
                                });
                              },
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          _rememberMe = value ?? false;
                                        });
                                      },
                                      activeColor: AppColors.primaryButton,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Remember me',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      color: Colors.grey.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context)
                                    .pushNamed('/forgot-password');
                              },
                              child: Text(
                                'Forgot password?',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryButton,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Error message
                        if (_loginError != null) ...[
                          Text(
                            _loginError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Log In Button
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryButton,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Log In',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward_rounded,
                                          size: 20),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Footer
                        Center(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                              children: [
                                const TextSpan(text: "Don't have an account? "),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.of(context)
                                          .pushReplacementNamed('/register');
                                    },
                                    child: Text(
                                      'Sign up',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryButton,
                                      ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1D26),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: errorText != null ? AppColors.error : Colors.grey.shade200,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword ? _obscurePassword : false,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14.5,
              ),
              prefixIcon: Icon(
                prefixIcon,
                size: 20,
                color: Colors.grey.shade500,
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: Colors.grey.shade500,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText,
            style: const TextStyle(
              color: AppColors.error,
              fontSize: 12.5,
            ),
          ),
        ],
      ],
    );
  }
}
