import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_text_styles.dart';
import '../data/mock_data.dart';
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

  final List<String> _languages = [
    'English',
    'Arabic',
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

  void _completeProfile() {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showMessage('Please enter your full name.');
      return;
    }

    // Temporarily save the main profile information locally.
    // Backend and database integration will be added later.
    CurrentUser.fullName = name;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const HomePage(),
      ),
      (route) => false,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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
          style: AppTextStyles.fieldLabel,
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
            fillColor: AppColors.fieldBackground,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.fieldBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.fieldBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.fieldBorderFocused,
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

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
          style: AppTextStyles.fieldLabel,
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
            fillColor: AppColors.fieldBackground,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.fieldBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.fieldBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.fieldBorderFocused,
                width: 1.4,
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        title,
        style: AppTextStyles.fieldLabel.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.darkCharcoal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 460,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Complete Your Profile',
                    style: AppTextStyles.heading.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkCharcoal,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Tell us a little about yourself to personalize your ScaleFlow experience.',
                    style: AppTextStyles.subtitle.copyWith(
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Profile Picture
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.tint(
                              AppColors.primaryButton,
                              0.10,
                            ),
                            border: Border.all(
                              color: AppColors.tint(
                                AppColors.primaryButton,
                                0.20,
                              ),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            size: 46,
                            color: AppColors.primaryButton,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: () {
                            _showMessage(
                              'Profile picture upload will be connected later.',
                            );
                          },
                          icon: const Icon(
                            Icons.camera_alt_outlined,
                            size: 18,
                            color: AppColors.primaryButton,
                          ),
                          label: Text(
                            'Add Profile Picture',
                            style: AppTextStyles.footerLink.copyWith(
                              color: AppColors.primaryButton,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Personal Information
                  _buildSectionTitle('Personal Information'),

                  _buildTextField(
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    controller: _nameController,
                  ),

                  const SizedBox(height: 18),

                  _buildTextField(
                    label: 'Job Title',
                    hint: 'e.g. Frontend Developer',
                    controller: _jobTitleController,
                  ),

                  const SizedBox(height: 18),

                  _buildDropdown(
                    label: 'Role',
                    value: _selectedRole,
                    items: _roles,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedRole = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 18),

                  _buildTextField(
                    label: 'Short Bio',
                    hint: 'Tell us briefly about yourself',
                    controller: _bioController,
                    maxLines: 3,
                  ),

                  const SizedBox(height: 28),

                  // Work Information
                  _buildSectionTitle('Work Information'),

                  _buildTextField(
                    label: 'Company / Organization',
                    hint: 'Enter your company or organization',
                    controller: _companyController,
                  ),

                  const SizedBox(height: 18),

                  _buildTextField(
                    label: 'Department',
                    hint: 'e.g. Development',
                    controller: _departmentController,
                  ),

                  const SizedBox(height: 28),

                  // Contact & Location
                  _buildSectionTitle('Contact & Location'),

                  _buildTextField(
                    label: 'Phone Number',
                    hint: 'Enter your phone number',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 18),

                  _buildDropdown(
                    label: 'Country',
                    value: _selectedCountry,
                    items: _countries,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCountry = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 18),

                  _buildTextField(
                    label: 'City',
                    hint: 'Enter your city',
                    controller: _cityController,
                  ),

                  const SizedBox(height: 28),

                  // Preferences
                  _buildSectionTitle('Preferences'),

                  _buildDropdown(
                    label: 'Language',
                    value: _selectedLanguage,
                    items: _languages,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedLanguage = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 18),

                  _buildDropdown(
                    label: 'Default View',
                    value: _selectedDefaultView,
                    items: _defaultViews,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedDefaultView = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notifications',
                              style: AppTextStyles.fieldLabel,
                            ),
                            const SizedBox(height: 3),
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
                          setState(() {
                            _notificationsEnabled = value;
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _completeProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryButton,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Continue to ScaleFlow',
                        style: AppTextStyles.buttonText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
