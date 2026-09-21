import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class GlobalPage extends StatelessWidget {
  const GlobalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // ------------------------------------------------
            // Background image
            // ------------------------------------------------
            Positioned.fill(
              child: Image.asset(
                'assets/images/global.jpg',
                fit: BoxFit.contain,
                alignment: Alignment.topCenter,
              ),
            ),

            // ------------------------------------------------
            // Soft white overlay at the bottom
            // ------------------------------------------------
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.white.withOpacity(0.12),
                        Colors.white.withOpacity(0.78),
                        Colors.white,
                      ],
                      stops: const [
                        0.0,
                        0.42,
                        0.58,
                        0.76,
                        1.0,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ------------------------------------------------
            // Logo 1 first
            // ------------------------------------------------
            Positioned(
              top: 18,
              left: 22,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/Logo1.png',
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),

            // ------------------------------------------------
            // Skip → Register
            // ------------------------------------------------
            Positioned(
              top: 54,
              right: 15,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RegisterScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.darkCharcoal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // ------------------------------------------------
            // Main Content
            // ------------------------------------------------
            Positioned(
              left: 28,
              right: 28,
              bottom: 48,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ------------------------------------------------
                  // Main title
                  // ------------------------------------------------
                  const Text(
                    'Smarter Project\nManagement',
                    style: TextStyle(
                      fontSize: 38,
                      height: 1.08,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkCharcoal,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ------------------------------------------------
                  // Subtitle
                  // ------------------------------------------------
                  const Text(
                    'AI-powered insights. Better decisions.\n'
                    'Successful projects.',
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 26),

                  // ------------------------------------------------
                  // Get Started → Register
                  // ------------------------------------------------
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.aiPurple,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 17),

                  // ------------------------------------------------
                  // Log In → Login
                  // ------------------------------------------------
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Already have an account? ',
                          ),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Log In',
                                style: TextStyle(
                                  color: AppColors.darkCharcoal,
                                  fontWeight: FontWeight.w700,
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
          ],
        ),
      ),
    );
  }
}
