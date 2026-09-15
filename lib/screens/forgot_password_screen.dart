import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_text_styles.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/scaleflow_logo.dart';

/// شاشة استرجاع كلمة السر (Forgot Password)
/// بتفتح لما تضغط "Forgot password?" بشاشة تسجيل الدخول، بنفس هوية التصميم
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  String? _emailError;
  bool _linkSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(value);
  }

  void _handleSendLink() {
    setState(() {
      if (_emailController.text.isEmpty) {
        _emailError = 'This field is required';
      } else if (!_isValidEmail(_emailController.text)) {
        _emailError = 'Please enter a valid email address';
      } else {
        _emailError = null;
        _linkSent = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
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
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back,
                                color: AppColors.textPrimary),
                          ),
                        ),
                        const Center(child: ScaleFlowLogo()),
                        const SizedBox(height: 24),
                        Text('Reset your password',
                            style: AppTextStyles.heading,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 6),
                        Text(
                          _linkSent
                              ? 'Check your inbox for the reset link.'
                              : "Enter your email and we'll send you a reset link.",
                          style: AppTextStyles.subtitle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        if (!_linkSent) ...[
                          CustomTextField(
                            label: 'Email Address',
                            hint: 'Enter your email',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            errorText: _emailError,
                            onChanged: (_) {
                              if (_emailError != null) {
                                setState(() => _emailError = null);
                              }
                            },
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _handleSendLink,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryButton,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                              ),
                              child: Text('Send Reset Link',
                                  style: AppTextStyles.buttonText),
                            ),
                          ),
                        ] else ...[
                          const Icon(Icons.mark_email_read_outlined,
                              size: 56, color: AppColors.primaryButton),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryButton,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                              ),
                              child: Text('Back to Log In',
                                  style: AppTextStyles.buttonText),
                            ),
                          ),
                        ],
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
