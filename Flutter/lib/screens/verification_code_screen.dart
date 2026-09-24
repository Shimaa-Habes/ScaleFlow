import 'dart:async';
import 'package:flutter/material.dart';
import 'complete_profile_screen.dart';
import '../data/mock_data.dart';

// ============================================================
// SCALEFLOW COLORS
// ============================================================

const Color _charcoal = Color(0xFF1A1D26);
const Color _mutedText = Color(0xFF555963);
const Color _border = Color(0xFFE2E4E8);
const Color _purple = Color(0xFF6C5CE7);
const Color _error = Color(0xFFE15C3E);
const Color _success = Color(0xFF61BD4F);

// ============================================================
// VERIFICATION CODE SCREEN
// ============================================================

class VerificationCodeScreen extends StatefulWidget {
  final String email;

  const VerificationCodeScreen({
    super.key,
    this.email = 'shimaa.habes@example.com',
  });

  @override
  State<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  // ==========================================================
  // CONTROLLERS
  // ==========================================================

  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());

  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  Timer? _timer;

  int _secondsRemaining = 30;

  bool _isLoading = false;
  bool _hasError = false;
  bool _isVerified = false;

  // ==========================================================
  // LIFECYCLE
  // ==========================================================

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();

    for (final controller in _controllers) {
      controller.dispose();
    }

    for (final node in _focusNodes) {
      node.dispose();
    }

    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF3F4F8),
                      Color(0xFFEAE8FF),
                      Color(0xFFF8FAFC),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _purple.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _purple.withOpacity(0.06),
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTopBar(),
                            const SizedBox(height: 20),
                            Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 420),
                                child: Column(
                                  children: [
                                    _buildVerificationIcon(),
                                    const SizedBox(height: 24),
                                    _buildTitle(),
                                    const SizedBox(height: 8),
                                    _buildDescription(),
                                    const SizedBox(height: 32),
                                    _buildCodeFields(),
                                    if (_hasError) ...[
                                      const SizedBox(height: 12),
                                      _buildErrorMessage(),
                                    ],
                                    const SizedBox(height: 28),
                                    _buildVerifyButton(),
                                    const SizedBox(height: 20),
                                    _buildResendSection(),
                                    const SizedBox(height: 24),
                                    _buildDemoHint(),
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
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // TOP BAR
  // ==========================================================

  Widget _buildTopBar() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        tooltip: 'Back',
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(
          Icons.arrow_back_ios_new,
          size: 16,
          color: _charcoal,
        ),
      ),
    );
  }

  // ==========================================================
  // VERIFICATION ICON
  // ==========================================================

  Widget _buildVerificationIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: _purple.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: _purple.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: const Icon(
        Icons.mark_email_unread_outlined,
        size: 36,
        color: _purple,
      ),
    );
  }

  // ==========================================================
  // TITLE
  // ==========================================================

  Widget _buildTitle() {
    return const Text(
      'Verify Your Email',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: _charcoal,
        letterSpacing: 0.5,
      ),
    );
  }

  // ==========================================================
  // DESCRIPTION
  // ==========================================================

  Widget _buildDescription() {
    return Column(
      children: [
        const Text(
          'We sent a 6-digit verification code to',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: _mutedText,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.email,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _charcoal,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // CODE FIELDS
  // ==========================================================

  Widget _buildCodeFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        6,
        (index) {
          return Container(
            width: 48,
            height: 56,
            margin: EdgeInsets.only(
              right: index == 5 ? 0 : 8,
            ),
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              keyboardType: TextInputType.number,
              textInputAction:
                  index == 5 ? TextInputAction.done : TextInputAction.next,
              textAlign: TextAlign.center,
              maxLength: 1,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _charcoal,
              ),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: _hasError ? _error : _border,
                    width: _hasError ? 1.5 : 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: _purple,
                    width: 1.8,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _hasError = false;
                });

                if (value.isNotEmpty && index < 5) {
                  _focusNodes[index + 1].requestFocus();
                }

                if (value.isEmpty && index > 0) {
                  _focusNodes[index - 1].requestFocus();
                }

                if (index == 5 && value.isNotEmpty) {
                  _focusNodes[index].unfocus();
                }
              },
              onSubmitted: (_) {
                if (index == 5) {
                  _verifyCode();
                }
              },
            ),
          );
        },
      ),
    );
  }

  // ==========================================================
  // ERROR MESSAGE
  // ==========================================================

  Widget _buildErrorMessage() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          size: 16,
          color: _error,
        ),
        SizedBox(width: 6),
        Text(
          'Invalid verification code. Please try again.',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _error,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // VERIFY BUTTON
  // ==========================================================

  Widget _buildVerifyButton() {
    final bool isComplete = _controllers.every(
      (controller) => controller.text.isNotEmpty,
    );

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isComplete && !_isLoading ? _verifyCode : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _purple,
          disabledBackgroundColor: const Color(0xFFD9D6F7),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          elevation: 4,
          shadowColor: _purple.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Verify Code',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  // ==========================================================
  // RESEND CODE
  // ==========================================================

  Widget _buildResendSection() {
    if (_secondsRemaining > 0) {
      return Text(
        'Resend code in 00:${_secondsRemaining.toString().padLeft(2, '0')}',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _mutedText,
        ),
      );
    }

    return TextButton(
      onPressed: _resendCode,
      child: const Text(
        'Resend Code',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _purple,
        ),
      ),
    );
  }

  // ==========================================================
  // DEMO HINT
  // ==========================================================

  Widget _buildDemoHint() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: _purple,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Try to verify your account.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _charcoal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TIMER
  // ==========================================================

  void _startTimer() {
    _timer?.cancel();

    setState(() {
      _secondsRemaining = 30;
    });

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (_secondsRemaining <= 1) {
          timer.cancel();

          if (mounted) {
            setState(() {
              _secondsRemaining = 0;
            });
          }

          return;
        }

        if (mounted) {
          setState(() {
            _secondsRemaining--;
          });
        }
      },
    );
  }

  // ==========================================================
  // RESEND
  // ==========================================================

  void _resendCode() {
    for (final controller in _controllers) {
      controller.clear();
    }

    setState(() {
      _hasError = false;
      _isVerified = false;
    });

    _startTimer();

    _focusNodes.first.requestFocus();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'A new verification code has been sent.',
        ),
      ),
    );
  }

  // ==========================================================
  // VERIFY
  // ==========================================================

  Future<void> _verifyCode() async {
    final code = _controllers.map((controller) => controller.text).join();

    if (code.length != 6) {
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    await Future.delayed(
      const Duration(milliseconds: 700),
    );

    if (!mounted) return;

    if (code == '917328') {
      setState(() {
        _isLoading = false;
        _isVerified = true;
      });

      _showSuccessMessage();

      await Future.delayed(
        const Duration(milliseconds: 800),
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CompleteProfileScreen(
            fullName: CurrentUser.fullName,
            email: widget.email,
          ),
        ),
      );
    } else {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _isVerified = false;
      });

      for (final controller in _controllers) {
        controller.clear();
      }

      _focusNodes.first.requestFocus();
    }
  }

  // ==========================================================
  // SUCCESS
  // ==========================================================

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: _success,
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'Email verified successfully!',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
