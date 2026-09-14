import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_text_styles.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/password_requirement_item.dart';
import '../widgets/scaleflow_logo.dart';

/// شاشة إنشاء حساب جديد (Register Screen)
/// نفس التنسيق والألوان المعتمدة بالتصميم:
/// عنوان + حقول (الاسم، الإيميل، كلمة السر، تأكيد كلمة السر)
/// + صندوق شروط كلمة السر + زر إنشاء الحساب + رابط تسجيل الدخول
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

  // خطأ مستقل لكل حقل — منقدر نعرض "This field is required" تحت أي
  // حقل فاضي لحاله، بدل ما نعتمد بس على حالة الإيميل/تأكيد كلمة السر
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  bool _has8Chars = false;
  bool _hasUppercase = false;
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
      _hasUppercase = value.contains(RegExp(r'[A-Z]'));
      _hasNumber = value.contains(RegExp(r'[0-9]'));
      if (_passwordError != null && value.isNotEmpty) {
        _passwordError = null;
      }
      // إذا تعدلت كلمة السر الأساسية، لازم نعيد فحص تطابقها مع الحقل
      // التاني (Confirm Password) بدل ما تبقى نتيجة الفحص القديمة معلّقة
      if (_confirmPasswordController.text.isNotEmpty) {
        _confirmPasswordError =
            _confirmPasswordController.text != value
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

  bool get _isPasswordFullyValid => _has8Chars && _hasUppercase && _hasNumber;

  /// بيتفحص كل الحقول الأربعة وقت الضغط على "Create Account"، وبيحط
  /// "This field is required" تحت أي حقل لسا فاضي — هاي بالضبط المشكلة
  /// اللي طلبت حلها.
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully ✅')),
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
              // تصميم متجاوب: نحدد عرض أقصى للمحتوى حتى يبقى مرتب
              // على الشاشات الكبيرة (تابلت / ويب) ويمتد على شاشات الموبايل
              final maxContentWidth =
                  constraints.maxWidth < 500 ? constraints.maxWidth : 420.0;

              return Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: ScaleFlowLogo()),
                        const SizedBox(height: 24),
                        Text('Create your account',
                            style: AppTextStyles.heading,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 6),
                        Text('Start managing your projects smarter.',
                            style: AppTextStyles.subtitle,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 28),

                        CustomTextField(
                          label: 'Full Name',
                          hint: 'Enter your full name',
                          controller: _nameController,
                          errorText: _nameError,
                          onChanged: (value) {
                            if (_nameError != null && value.trim().isNotEmpty) {
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
                        const SizedBox(height: 16),

                        CustomTextField(
                          label: 'Confirm Password',
                          hint: 'Confirm your password',
                          controller: _confirmPasswordController,
                          isPassword: true,
                          errorText: _confirmPasswordError,
                          isValid: _confirmPasswordController.text.isNotEmpty &&
                              _confirmPasswordError == null &&
                              _confirmPasswordController.text ==
                                  _passwordController.text,
                          onChanged: _validateConfirmPassword,
                        ),
                        const SizedBox(height: 16),

                        // صندوق شروط كلمة السر
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.hintBoxBackground,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Password must contain:',
                                  style: AppTextStyles.hintBoxTitle),
                              const SizedBox(height: 6),
                              PasswordRequirementItem(
                                text: '8+ characters',
                                isSatisfied: _has8Chars,
                              ),
                              PasswordRequirementItem(
                                text: 'One uppercase letter',
                                isSatisfied: _hasUppercase,
                              ),
                              PasswordRequirementItem(
                                text: 'One number',
                                isSatisfied: _hasNumber,
                              ),
                            ],
                          ),
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
                            child: Text('Create Account',
                                style: AppTextStyles.buttonText),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Center(
                          child: RichText(
                            text: TextSpan(
                              style: AppTextStyles.footerText,
                              children: [
                                const TextSpan(text: 'Already have an account? '),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.of(context)
                                          .pushReplacementNamed('/login');
                                    },
                                    child: Text('Log in',
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
