import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_text_styles.dart';
import '../data/mock_data.dart';
import '../widgets/custom_text_field.dart';
import 'verification_code_screen.dart';
// import '../widgets/password_requirement_item.dart';

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

  // Stores the validation error for each field.
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  // Tracks password requirements while the user types.
  bool _has8Chars = false;
  bool _hasLetter = false;
  bool _hasUppercase = false;
  bool _hasSpecialSymbol = false;
  bool _hasNumber = false;

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

      // Revalidate the confirmation password whenever the main password changes.
      if (_confirmPasswordController.text.isNotEmpty) {
        _confirmPasswordError = _confirmPasswordController.text != value
            ? 'Passwords do not match'
            : null;
      }
    });
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

  void _validateConfirmPassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _confirmPasswordError = null;
      } else if (value != _passwordController.text) {
        _confirmPasswordError = 'Passwords do not match';
      } else {
        _confirmPasswordError = null;
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

  void _handleCreateAccount() {
    setState(() {
      _nameError =
          _nameController.text.trim().isEmpty ? 'This field is required' : null;

      if (_emailController.text.isEmpty) {
        _emailError = 'This field is required';
      } else if (!_isValidEmail(_emailController.text)) {
        _emailError = 'Please enter a valid email address';
      } else {
        _emailError = null;
      }

      if (_passwordController.text.isEmpty) {
        _passwordError = 'This field is required';
      } else if (!_isPasswordFullyValid) {
        _passwordError = 'Password does not meet all requirements';
      } else {
        _passwordError = null;
      }

      if (_confirmPasswordController.text.isEmpty) {
        _confirmPasswordError = 'This field is required';
      } else if (_confirmPasswordController.text != _passwordController.text) {
        _confirmPasswordError = 'Passwords do not match';
      } else {
        _confirmPasswordError = null;
      }
    });

    final allValid = _nameError == null &&
        _emailError == null &&
        _passwordError == null &&
        _confirmPasswordError == null;

    if (allValid) {
      // Save the registered user using the current mock authentication flow.
      CurrentUser.register(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Continue to verification after successful registration.
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VerificationCodeScreen(
            email: _emailController.text.trim(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        body: Stack(
          children: [
            // 1. خلفية الصورة (Reg-Image.jpg) بملء الشاشة
            Positioned.fill(
              child: Image.asset(
                'assets/images/Reg-Image.jpg',
                fit: BoxFit.cover,
              ),
            ),

            // 2. طبقة تعتيم (Overlay) لضمان تباين الألوان ووضوح النصوص وحقول الإدخال
            Positioned.fill(
              child: Container(
                color: AppColors.background.withOpacity(0.85),
              ),
            ),

            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Limit the content width on larger screens.
                  final maxContentWidth =
                      constraints.maxWidth < 500 ? constraints.maxWidth : 420.0;

                  return Stack(
                    children: [
                      Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(
                            24,
                            48, // ترك مساحة للأعلى لكي لا يتداخل السهم مع المحتوى
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
                                // Display the official ScaleFlow logo.
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
                                      setState(() => _nameError = null);
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
                                      _isValidEmail(_emailController.text),
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

                                // Show password strength only after the user starts typing.
                                if (_passwordController.text.isNotEmpty) ...[
                                  const SizedBox(height: 10),

                                  Row(
                                    children: [
                                      Text(
                                        _passwordStrengthEmoji,
                                        style: const TextStyle(fontSize: 18),
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

                                  // Thin password strength indicator.
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

                                const SizedBox(height: 24),

                                SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _handleCreateAccount,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryButton,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
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
                                                      '/login');
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

                      // سهم الرجوع في أعلى اليسار للعودة إلى صفحة جلوبال (Global)
                      Positioned(
                        top: 8,
                        left: 16,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                          color: AppColors.primaryButton,
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            } else {
                              Navigator.pushReplacementNamed(
                                  context, '/global');
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
}
