import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_text_styles.dart';
import '../widgets/custom_text_field.dart';
import '../services/auth_service.dart';
import 'verification_code_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final AuthService _authService = AuthService();

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _registerError;

  bool _has8Chars = false;
  bool _hasLetter = false;
  bool _hasUppercase = false;
  bool _hasSpecialSymbol = false;
  bool _hasNumber = false;

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onPasswordChanged(String value) {
    setState(() {
      _has8Chars = value.length >= 8;
      _hasLetter = value.contains(RegExp(r'[A-Za-z]'));
      _hasUppercase = value.contains(RegExp(r'[A-Z]'));
      _hasSpecialSymbol = value.contains(RegExp(r'[^A-Za-z0-9]'));
      _hasNumber = value.contains(RegExp(r'[0-9]'));

      if (_passwordError != null && value.isNotEmpty) {
        _passwordError = null;
      }

      if (_registerError != null) {
        _registerError = null;
      }

      if (_confirmPasswordController.text.isNotEmpty) {
        _confirmPasswordError = _confirmPasswordController.text != value
            ? 'Passwords do not match'
            : null;
      }
    });
  }

  bool _isValidEmail(String value) {
    return RegExp(
      r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(value);
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

      if (_registerError != null) {
        _registerError = null;
      }
    });
  }

  void _validateConfirmPassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _confirmPasswordError = null;
      } else if (value != _passwordController.text) {
        _confirmPasswordError = 'Passwords do not match';
      } else {
        _confirmPasswordError = null;
      }

      if (_registerError != null) {
        _registerError = null;
      }
    });
  }

  bool get _isPasswordFullyValid =>
      _has8Chars &&
      _hasLetter &&
      _hasUppercase &&
      _hasSpecialSymbol &&
      _hasNumber;

  String get _passwordStrengthEmoji {
    if (_passwordController.text.isEmpty) {
      return '';
    }

    if (!_has8Chars) {
      return '😖';
    }

    if (!_hasUppercase) {
      return '😐';
    }

    if (!_hasNumber || !_hasSpecialSymbol) {
      return '😉';
    }

    return '😎';
  }

  String get _passwordStrengthText {
    if (_passwordController.text.isEmpty) {
      return '';
    }

    if (!_has8Chars) {
      return 'Weak. Must contain at least 8 characters';
    }

    if (!_hasUppercase) {
      return 'Almost. Must contain an uppercase letter';
    }

    if (!_hasNumber || !_hasSpecialSymbol) {
      return 'Almost. Must contain a number and special symbol';
    }

    return 'Awesome! You have a secure password.';
  }

  Color get _passwordStrengthColor {
    if (_passwordController.text.isEmpty) {
      return Colors.transparent;
    }

    if (!_has8Chars) {
      return Colors.red;
    }

    if (!_hasLetter) {
      return Colors.amber;
    }

    if (!_hasSpecialSymbol) {
      return Colors.orange;
    }

    return Colors.green;
  }

  double get _passwordStrengthValue {
    if (_passwordController.text.isEmpty) {
      return 0;
    }

    int score = 0;

    if (_has8Chars) score++;
    if (_hasLetter) score++;
    if (_hasSpecialSymbol) score++;
    if (_hasNumber) score++;

    return score / 4;
  }

  Future<void> _handleCreateAccount() async {
    FocusScope.of(context).unfocus();

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      _nameError = name.isEmpty ? 'This field is required' : null;

      if (email.isEmpty) {
        _emailError = 'This field is required';
      } else if (!_isValidEmail(email)) {
        _emailError = 'Please enter a valid email address';
      } else {
        _emailError = null;
      }

      if (password.isEmpty) {
        _passwordError = 'This field is required';
      } else if (!_isPasswordFullyValid) {
        _passwordError = 'Password does not meet all requirements';
      } else {
        _passwordError = null;
      }

      if (confirmPassword.isEmpty) {
        _confirmPasswordError = 'This field is required';
      } else if (confirmPassword != password) {
        _confirmPasswordError = 'Passwords do not match';
      } else {
        _confirmPasswordError = null;
      }

      _registerError = null;
    });

    final allValid = _nameError == null &&
        _emailError == null &&
        _passwordError == null &&
        _confirmPasswordError == null;

    if (!allValid) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('========== REGISTER REQUEST ==========');
      print('Name: $name');
      print('Email: $email');
      print('Password length: ${password.length}');
      print('======================================');

      final result = await _authService.register(
        name,
        email,
        password,
      );

      if (!result['success']) {
        setState(() {
          _isLoading = false;
          _registerError = result['message'] ?? 'Registration failed.';
        });
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully ✅'),
        ),
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VerificationCodeScreen(
            email: email,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _registerError = 'Registration failed. Please try again.';
      });

      print('========== REGISTER SCREEN ERROR ==========');
      print(e);
      print('===========================================');
    }
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
                'assets/images/Reg-Image.jpg',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(
                color: AppColors.background.withOpacity(0.85),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxContentWidth =
                      constraints.maxWidth < 500 ? constraints.maxWidth : 420.0;

                  return Stack(
                    children: [
                      Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(
                            24,
                            48,
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
                                Center(
                                  child: Image.asset(
                                    'assets/images/Logo.png',
                                    width: 200,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Create your account',
                                  style: AppTextStyles.heading,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Start managing your projects smarter.',
                                  style: AppTextStyles.subtitle,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 28),
                                CustomTextField(
                                  label: 'Full Name',
                                  hint: 'Enter your full name',
                                  controller: _nameController,
                                  errorText: _nameError,
                                  onChanged: (value) {
                                    if (_nameError != null &&
                                        value.trim().isNotEmpty) {
                                      setState(() {
                                        _nameError = null;
                                      });
                                    }

                                    if (_registerError != null) {
                                      setState(() {
                                        _registerError = null;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  label: 'Email Address',
                                  hint: 'Enter your email',
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  errorText: _emailError,
                                  isValid: _emailError == null &&
                                      _emailController.text.isNotEmpty &&
                                      _isValidEmail(
                                        _emailController.text,
                                      ),
                                  onChanged: _validateEmail,
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  label: 'Password',
                                  hint: 'Create your password',
                                  controller: _passwordController,
                                  isPassword: true,
                                  errorText: _passwordError,
                                  onChanged: _onPasswordChanged,
                                ),
                                if (_passwordController.text.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Text(
                                        _passwordStrengthEmoji,
                                        style: const TextStyle(
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _passwordStrengthText,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _passwordStrengthColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      height: 3,
                                      child: LinearProgressIndicator(
                                        value: _passwordStrengthValue,
                                        backgroundColor: Colors.grey.shade200,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          _passwordStrengthColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                CustomTextField(
                                  label: 'Confirm Password',
                                  hint: 'Confirm your password',
                                  controller: _confirmPasswordController,
                                  isPassword: true,
                                  errorText: _confirmPasswordError,
                                  isValid: _confirmPasswordController
                                          .text.isNotEmpty &&
                                      _confirmPasswordError == null &&
                                      _confirmPasswordController.text ==
                                          _passwordController.text,
                                  onChanged: _validateConfirmPassword,
                                ),
                                const SizedBox(height: 20),
                                if (_registerError != null) ...[
                                  Text(
                                    _registerError!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                ],
                                SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _handleCreateAccount,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryButton,
                                      disabledBackgroundColor: AppColors
                                          .primaryButton
                                          .withOpacity(0.6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          14,
                                        ),
                                      ),
                                      elevation: 0,
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
                                        : Text(
                                            'Create Account',
                                            style: AppTextStyles.buttonText,
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Center(
                                  child: RichText(
                                    text: TextSpan(
                                      style: AppTextStyles.footerText,
                                      children: [
                                        const TextSpan(
                                          text: 'Already have an account? ',
                                        ),
                                        WidgetSpan(
                                          alignment:
                                              PlaceholderAlignment.middle,
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.of(context)
                                                  .pushReplacementNamed(
                                                '/login',
                                              );
                                            },
                                            child: Text(
                                              'Log in',
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
                      ),
                      Positioned(
                        top: 8,
                        left: 16,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 20,
                          ),
                          color: AppColors.primaryButton,
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            } else {
                              Navigator.pushReplacementNamed(
                                context,
                                '/global',
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
