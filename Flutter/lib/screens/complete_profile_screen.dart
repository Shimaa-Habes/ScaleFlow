import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/app_colors.dart';
import '../core/app_text_styles.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  final String fullName;
  final String email;

  const CompleteProfileScreen({
    super.key,
    required this.fullName,
    required this.email,
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  late final TextEditingController _nameController;

  final TextEditingController _jobTitleController = TextEditingController();

  final TextEditingController _companyController = TextEditingController();

  final TextEditingController _departmentController = TextEditingController();

  final TextEditingController _phoneController = TextEditingController();

  final TextEditingController _cityController = TextEditingController();

  final TextEditingController _bioController = TextEditingController();

  String _selectedRole = 'Team Member';

  String _selectedCountry = 'Palestine';

  String _selectedLanguage = 'English';

  String _selectedDefaultView = 'Projects';

  bool _notificationsEnabled = true;

  bool _isSaving = false;

  final List<String> _roles = [
    'Project Manager',
    'Team Leader',
    'Team Member',
    'Client',
  ];

  final List<String> _countries = [
    'Palestine',
    'Jordan',
    'Saudi Arabia',
    'United Arab Emirates',
    'Egypt',
    'Other',
  ];

  final List<String> _defaultViews = [
    'Projects',
    'Home',
    'Tasks',
    'AI Insights',
  ];

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.fullName,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _jobTitleController.dispose();
    _companyController.dispose();
    _departmentController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _bioController.dispose();

    super.dispose();
  }

  // ============================================================
  // SAVE COMPLETE PROFILE
  // ============================================================

  Future<void> _completeProfile() async {
    if (_isSaving) {
      return;
    }

    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showMessage('Please enter your full name.');
      return;
    }

    final token = AuthService.accessToken;

    if (token == null || token.isEmpty) {
      _showMessage(
        'Your session has expired. Please log in again.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final response = await http.put(
        Uri.parse(
          'http://localhost:5233/api/Profile/me',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fullName': name,
          'jobTitle': _jobTitleController.text.trim(),
          'company': _companyController.text.trim(),
          'department': _departmentController.text.trim(),
          'phone': _phoneController.text.trim(),
          'country': _selectedCountry,
          'city': _cityController.text.trim(),
          'shortBio': _bioController.text.trim(),
          'language': _selectedLanguage,
          'defaultView': _selectedDefaultView,
          'notificationsEnabled': _notificationsEnabled,
        }),
      );

      print('========== PROFILE UPDATE ==========');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('=====================================');

      Map<String, dynamic> responseData = {};

      try {
        responseData = jsonDecode(response.body);
      } catch (_) {
        responseData = {};
      }

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200) {
        _showMessage(
          responseData['message'] ?? 'Profile completed successfully.',
        );

        await Future.delayed(
          const Duration(milliseconds: 500),
        );

        if (!mounted) {
          return;
        }

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const HomePage(),
          ),
          (route) => false,
        );

        return;
      }

      if (response.statusCode == 401) {
        AuthService.logout();

        _showMessage(
          'Your session has expired. Please log in again.',
        );

        return;
      }

      _showMessage(
        responseData['message'] ??
            'Unable to save your profile. Please try again.',
      );
    } catch (e) {
      print('========== PROFILE UPDATE ERROR ==========');
      print(e);
      print('==========================================');

      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to connect to the server. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.darkCharcoal,
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.fieldLabel.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: AppTextStyles.fieldInput,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.fieldPlaceholder,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppColors.primaryButton,
                width: 1.6,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DROPDOWN
  // ============================================================

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.fieldLabel.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          onChanged: onChanged,
          style: AppTextStyles.fieldInput,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppColors.primaryButton,
                width: 1.6,
              ),
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryButton.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryButton,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkCharcoal,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(
              vertical: 16,
            ),
            child: Divider(
              color: Color(0xFFEDF2F7),
              height: 1,
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

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
                  color: AppColors.primaryButton.withOpacity(0.08),
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
                  color: AppColors.primaryButton.withOpacity(0.06),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  24,
                  20,
                  40,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 480,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Complete Your Profile',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.heading.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkCharcoal,
                            letterSpacing: 0.5,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        Text(
                          'Tell us a little about yourself to personalize your ScaleFlow experience.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.subtitle.copyWith(
                            fontSize: 14,
                            height: 1.5,
                            color: const Color(
                              0xFF64748B,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 32,
                        ),

                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primaryButton,
                                    AppColors.primaryButton.withOpacity(
                                      0.6,
                                    ),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryButton.withOpacity(
                                      0.3,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(
                                      0,
                                      8,
                                    ),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    size: 50,
                                    color: AppColors.primaryButton,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.primaryButton,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  _showMessage(
                                    'Profile picture upload will be connected later.',
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 36,
                        ),

                        // ==================================================
                        // PERSONAL INFORMATION
                        // ==================================================

                        _buildSectionCard(
                          title: 'Personal Information',
                          icon: Icons.person_outline_rounded,
                          children: [
                            _buildTextField(
                              label: 'Full Name',
                              hint: 'Enter your full name',
                              controller: _nameController,
                            ),
                            const SizedBox(
                              height: 18,
                            ),
                            _buildTextField(
                              label: 'Job Title',
                              hint: 'e.g. Frontend Developer',
                              controller: _jobTitleController,
                            ),
                            const SizedBox(
                              height: 18,
                            ),
                            _buildDropdown(
                              label: 'Role',
                              value: _selectedRole,
                              items: _roles,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(
                                    () => _selectedRole = value,
                                  );
                                }
                              },
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            Text(
                              'Your system role is managed by ScaleFlow permissions.',
                              style: AppTextStyles.subtitle.copyWith(
                                fontSize: 11.5,
                                color: const Color(
                                  0xFF94A3B8,
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 18,
                            ),
                            _buildTextField(
                              label: 'Short Bio',
                              hint: 'Tell us briefly about yourself',
                              controller: _bioController,
                              maxLines: 3,
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 24,
                        ),

                        // ==================================================
                        // WORK INFORMATION
                        // ==================================================

                        _buildSectionCard(
                          title: 'Work Information',
                          icon: Icons.business_rounded,
                          children: [
                            _buildTextField(
                              label: 'Company / Organization',
                              hint: 'Enter your company or organization',
                              controller: _companyController,
                            ),
                            const SizedBox(
                              height: 18,
                            ),
                            _buildTextField(
                              label: 'Department',
                              hint: 'e.g. Development',
                              controller: _departmentController,
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 24,
                        ),

                        // ==================================================
                        // CONTACT & LOCATION
                        // ==================================================

                        _buildSectionCard(
                          title: 'Contact & Location',
                          icon: Icons.location_on_outlined,
                          children: [
                            _buildTextField(
                              label: 'Phone Number',
                              hint: 'Enter your phone number',
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(
                              height: 18,
                            ),
                            _buildDropdown(
                              label: 'Country',
                              value: _selectedCountry,
                              items: _countries,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(
                                    () => _selectedCountry = value,
                                  );
                                }
                              },
                            ),
                            const SizedBox(
                              height: 18,
                            ),
                            _buildTextField(
                              label: 'City',
                              hint: 'Enter your city',
                              controller: _cityController,
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 24,
                        ),

                        // ==================================================
                        // PREFERENCES
                        // ==================================================

                        _buildSectionCard(
                          title: 'Preferences & Settings',
                          icon: Icons.tune_rounded,
                          children: [
                            const SizedBox(
                              height: 18,
                            ),
                            _buildDropdown(
                              label: 'Default View',
                              value: _selectedDefaultView,
                              items: _defaultViews,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(
                                    () => _selectedDefaultView = value,
                                  );
                                }
                              },
                            ),
                            const SizedBox(
                              height: 18,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Notifications',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(
                                            0xFF2C3E50,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 3,
                                      ),
                                      Text(
                                        'Receive important project updates',
                                        style: AppTextStyles.subtitle.copyWith(
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch.adaptive(
                                  value: _notificationsEnabled,
                                  activeColor: AppColors.primaryButton,
                                  onChanged: (value) {
                                    setState(
                                      () => _notificationsEnabled = value,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 36,
                        ),

                        // ==================================================
                        // CONTINUE BUTTON
                        // ==================================================

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _completeProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryButton,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  AppColors.primaryButton.withOpacity(
                                0.55,
                              ),
                              elevation: 4,
                              shadowColor: AppColors.primaryButton.withOpacity(
                                0.4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  30,
                                ),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Continue to ScaleFlow',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 8,
                                      ),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 20,
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
}
