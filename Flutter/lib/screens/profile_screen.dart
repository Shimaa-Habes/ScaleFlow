import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../data/mock_data.dart';
import '../services/auth_service.dart';
import '../widgets/scaleflow_bottom_nav.dart';

import 'dashboard_screen.dart';
import 'ai_insights_screen.dart';
import 'projects_screen.dart';
import 'home_screen.dart';

// ============================================================
// SCALEFLOW COLORS
// ============================================================

const Color _charcoal = Color(0xFF2C2D30);
const Color _softText = Color(0xFF666A70);
const Color _mutedText = Color(0xFF858990);
const Color _border = Color(0xFFE5E6E9);
const Color _surface = Color(0xFFFFFFFF);
const Color _pageBackground = Color(0xFFF6F7FB);
const Color _purple = Color(0xFF6C5CE7);
const Color _blue = Color(0xFF5B9BD5);
const Color _green = Color(0xFF61BD4F);
const Color _cyan = Color(0xFF26C6DA);
const Color _coral = Color(0xFFFF6B4A);

// ============================================================
// PROFILE SCREEN
// ============================================================

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ==========================================================
  // BACKEND
  // ==========================================================

  static const String _profileUrl = 'http://localhost:5233/api/Profile/me';

  bool _isLoadingProfile = true;
  bool _isSavingProfile = false;

  // ==========================================================
  // PROFILE STATE
  // All persisted profile information comes from the backend.
  // ==========================================================

  String _userName = '';
  String _userEmail = '';
  String _userJobTitle = '';
  String _userRole = '';
  String _userCompany = '';
  String _userDepartment = '';
  String _userPhoneNumber = '';
  String _userCountry = '';
  String _userCity = '';
  String _userShortBio = '';
  String _selectedDefaultView = 'Projects';
  String _userLanguage = 'English';
  bool _notificationsEnabled = true;

  // ==========================================================
  // LOCAL AVATAR
  //
  // Avatar is local only for now.
  // The backend does not currently expose an image upload
  // endpoint.
  // ==========================================================

  final ImagePicker _profileImagePicker = ImagePicker();

  Uint8List? _profileImage;

  // ==========================================================
  // GETTERS
  // ==========================================================

  String get userName => _userName;

  String get userEmail => _userEmail;

  String get userJobTitle => _userJobTitle;

  String get userRole => _userRole;

  String get userCompany => _userCompany;

  String get userDepartment => _userDepartment;

  String get userPhoneNumber => _userPhoneNumber;

  String get userCountry => _userCountry;

  String get userCity => _userCity;

  String get userShortBio => _userShortBio;

  String get selectedDefaultView => _selectedDefaultView;

  bool get notificationsEnabled => _notificationsEnabled;

  // ==========================================================
  // LIFECYCLE
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _loadProfile();
  }

  // ==========================================================
  // LOAD PROFILE
  // GET /api/Profile/me
  // ==========================================================

  Future<void> _loadProfile() async {
    final token = AuthService.accessToken;

    if (token == null || token.isEmpty) {
      if (!mounted) return;

      setState(() {
        _isLoadingProfile = false;
      });

      _goToLogin();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(_profileUrl),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('========== PROFILE GET RESPONSE ==========');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('==========================================');

      Map<String, dynamic> responseData = {};

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          responseData = decoded;
        }
      } catch (_) {
        responseData = {};
      }

      if (response.statusCode == 200) {
        final data = responseData['data'];

        if (data is Map<String, dynamic>) {
          _applyProfileData(data);
        }

        if (!mounted) return;

        setState(() {
          _isLoadingProfile = false;
        });

        return;
      }

      if (response.statusCode == 401) {
        AuthService.logout();

        if (!mounted) return;

        setState(() {
          _isLoadingProfile = false;
        });

        _showMessage(
          'Your session has expired. Please log in again.',
        );

        _goToLogin();
        return;
      }

      if (!mounted) return;

      setState(() {
        _isLoadingProfile = false;
      });

      _showMessage(
        responseData['message']?.toString() ?? 'Unable to load your profile.',
      );
    } catch (e) {
      print('========== PROFILE GET ERROR ==========');
      print(e);
      print('======================================');

      if (!mounted) return;

      setState(() {
        _isLoadingProfile = false;
      });

      _showMessage(
        'Unable to connect to the server. Please try again.',
      );
    }
  }

  // ==========================================================
  // APPLY PROFILE DATA
  // Backend -> ProfileScreen
  // ==========================================================

  void _applyProfileData(Map<String, dynamic> data) {
    final fullName = data['fullName']?.toString().trim() ?? '';

    final email = data['email']?.toString().trim() ?? '';

    final jobTitle = data['jobTitle']?.toString().trim() ?? '';

    final role = data['role']?.toString().trim() ?? '';

    final company = data['company']?.toString().trim() ?? '';

    final department = data['department']?.toString().trim() ?? '';

    final phone = data['phone']?.toString().trim() ?? '';

    final country = data['country']?.toString().trim() ?? '';

    final city = data['city']?.toString().trim() ?? '';

    final shortBio = data['shortBio']?.toString().trim() ?? '';

    final language = data['language']?.toString().trim().isNotEmpty == true
        ? data['language'].toString().trim()
        : 'English';

    final defaultView =
        data['defaultView']?.toString().trim().isNotEmpty == true
            ? data['defaultView'].toString().trim()
            : 'Projects';

    final notifications = data['notificationsEnabled'] == true;

    if (!mounted) return;

    setState(() {
      _userName = fullName;
      _userEmail = email;
      _userJobTitle = jobTitle;
      _userRole = role;
      _userCompany = company;
      _userDepartment = department;
      _userPhoneNumber = phone;
      _userCountry = country;
      _userCity = city;
      _userShortBio = shortBio;
      _userLanguage = language;
      _selectedDefaultView = defaultView;
      _notificationsEnabled = notifications;
    });

    // ----------------------------------------------------------
    // Synchronize the existing local CurrentUser cache.
    //
    // Other screens may still use CurrentUser, so we keep it
    // synchronized while ProfileScreen itself uses the backend.
    // ----------------------------------------------------------

    CurrentUser.fullName = fullName;
    CurrentUser.email = email;
    CurrentUser.jobTitle = jobTitle;
    CurrentUser.role = role;
    CurrentUser.company = company;
    CurrentUser.department = department;
    CurrentUser.phoneNumber = phone;
    CurrentUser.country = country;
    CurrentUser.city = city;
    CurrentUser.shortBio = shortBio;
    CurrentUser.language = language;
    CurrentUser.defaultView = defaultView;
    CurrentUser.notificationsEnabled = notifications;
  }

  // ==========================================================
  // UPDATE PROFILE
  // PUT /api/Profile/me
  // ==========================================================

  Future<bool> _updateProfile({
    required String fullName,
    required String jobTitle,
    required String company,
    required String department,
    required String phone,
    required String country,
    required String city,
    required String shortBio,
    required String language,
    required String defaultView,
    required bool notificationsEnabled,
  }) async {
    final token = AuthService.accessToken;

    if (token == null || token.isEmpty) {
      _goToLogin();
      return false;
    }

    if (fullName.trim().isEmpty) {
      _showMessage('Full name is required.');
      return false;
    }

    if (mounted) {
      setState(() {
        _isSavingProfile = true;
      });
    }

    try {
      final response = await http.put(
        Uri.parse(_profileUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fullName': fullName.trim(),
          'jobTitle': _cleanValue(jobTitle),
          'company': _cleanValue(company),
          'department': _cleanValue(department),
          'phone': _cleanValue(phone),
          'country': _cleanValue(country),
          'city': _cleanValue(city),
          'shortBio': _cleanValue(shortBio),
          'language': _cleanValue(language),
          'defaultView':
              defaultView.trim().isEmpty ? 'Projects' : defaultView.trim(),
          'notificationsEnabled': notificationsEnabled,
        }),
      );

      print('========== PROFILE PUT RESPONSE ==========');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('==========================================');

      Map<String, dynamic> responseData = {};

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          responseData = decoded;
        }
      } catch (_) {
        responseData = {};
      }

      if (response.statusCode == 200) {
        final data = responseData['data'];

        if (data is Map<String, dynamic>) {
          _applyProfileData(data);
        } else if (mounted) {
          setState(() {
            _userName = fullName.trim();
            _userJobTitle = jobTitle.trim();
            _userCompany = company.trim();
            _userDepartment = department.trim();
            _userPhoneNumber = phone.trim();
            _userCountry = country.trim();
            _userCity = city.trim();
            _userShortBio = shortBio.trim();
            _userLanguage =
                language.trim().isEmpty ? 'English' : language.trim();
            _selectedDefaultView =
                defaultView.trim().isEmpty ? 'Projects' : defaultView.trim();
            _notificationsEnabled = notificationsEnabled;
          });
        }

        if (mounted) {
          setState(() {
            _isSavingProfile = false;
          });
        }

        return true;
      }

      if (response.statusCode == 401) {
        AuthService.logout();

        if (!mounted) return false;

        setState(() {
          _isSavingProfile = false;
        });

        _showMessage(
          'Your session has expired. Please log in again.',
        );

        _goToLogin();

        return false;
      }

      if (mounted) {
        setState(() {
          _isSavingProfile = false;
        });
      }

      _showMessage(
        responseData['message']?.toString() ?? 'Unable to update your profile.',
      );

      return false;
    } catch (e) {
      print('========== PROFILE PUT ERROR ==========');
      print(e);
      print('=======================================');

      if (!mounted) return false;

      setState(() {
        _isSavingProfile = false;
      });

      _showMessage(
        'Unable to connect to the server. Please try again.',
      );

      return false;
    }
  }

  // ==========================================================
  // CLEAN VALUE
  // ==========================================================

  String? _cleanValue(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  // ==========================================================
  // LOGIN NAVIGATION
  // ==========================================================

  void _goToLogin() {
    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  // ==========================================================
  // MESSAGE
  // ==========================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ==========================================================
  // MAIN BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _isLoadingProfile
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: _purple,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        90,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileHeader(),
                          const SizedBox(height: 24),
                          _buildSectionTitle(
                            'Account Overview',
                          ),
                          const SizedBox(height: 10),
                          _buildAccountOverview(),
                          const SizedBox(height: 24),
                          _buildSectionTitle(
                            'Profile Information',
                          ),
                          const SizedBox(height: 10),
                          _buildProfileInformation(),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Account'),
                          const SizedBox(height: 10),
                          _buildSettingTile(
                            icon: Icons.person_outline,
                            title: 'Edit Profile',
                            subtitle: 'Update your profile information',
                            trailing: const Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: _mutedText,
                            ),
                            onTap: _openEditProfile,
                          ),
                          _buildSettingTile(
                            icon: Icons.notifications_none_outlined,
                            title: 'Notifications',
                            subtitle: notificationsEnabled
                                ? 'Notifications are enabled'
                                : 'Notifications are disabled',
                            trailing: Switch(
                              value: notificationsEnabled,
                              onChanged: _changeNotifications,
                              activeColor: Colors.white,
                              activeTrackColor: _green,
                            ),
                            onTap: () {
                              _changeNotifications(
                                !notificationsEnabled,
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildSectionTitle(
                            'Preferences',
                          ),
                          const SizedBox(height: 10),
                          _buildSettingTile(
                            icon: Icons.dashboard_outlined,
                            title: 'Default View',
                            subtitle: 'Choose the screen shown first',
                            trailing: _buildTrailingText(
                              selectedDefaultView,
                            ),
                            onTap: _openDefaultViewSettings,
                          ),
                          const SizedBox(height: 16),
                          _buildSectionTitle(
                            'Security & Privacy',
                          ),
                          const SizedBox(height: 10),
                          _buildSettingTile(
                            icon: Icons.lock_outline,
                            title: 'Password & Security',
                            subtitle: 'Manage your account security',
                            trailing: const Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: _mutedText,
                            ),
                            onTap: _openPasswordSecurity,
                          ),
                          _buildSettingTile(
                            icon: Icons.privacy_tip_outlined,
                            title: 'Privacy & Data',
                            subtitle: 'Manage privacy and data preferences',
                            trailing: const Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: _mutedText,
                            ),
                            onTap: _openPrivacySettings,
                          ),
                          const SizedBox(height: 16),
                          _buildSectionTitle('Support'),
                          const SizedBox(height: 10),
                          _buildSettingTile(
                            icon: Icons.help_outline,
                            title: 'Help & Support',
                            subtitle: 'Get help with ScaleFlow',
                            trailing: const Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: _mutedText,
                            ),
                            onTap: _openHelpSupport,
                          ),
                          const SizedBox(height: 18),
                          _buildLogOutButton(),
                          const SizedBox(height: 24),
                          const Center(
                            child: Text(
                              'ScaleFlow • BinX Tech Team 04',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF9A9DA2),
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

      // ========================================================
      // BOTTOM NAVIGATION
      // Home → Projects → Dashboard → AI → Profile
      // ========================================================

      bottomNavigationBar: ScaleFlowBottomNav(
        currentIndex: 4,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const HomePage(),
              ),
            );
          } else if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ProjectsScreen(),
              ),
            );
          } else if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const DashboardPage(),
              ),
            );
          } else if (index == 3) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AiInsightsPage(),
              ),
            );
          }
        },
      ),
    );
  }

  // ==========================================================
  // TOP BAR
  // ==========================================================

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        12,
        6,
        12,
        4,
      ),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: IconButton(
                tooltip: 'Back',
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 18,
                  color: _charcoal,
                ),
              ),
            ),
            const Expanded(
              child: Center(
                child: Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _charcoal,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // PROFILE HEADER
  // ==========================================================

  Widget _buildProfileHeader() {
    final Uint8List? imageBytes = _profileImage;

    return Center(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE9EAED),
                  border: Border.all(
                    color: const Color(0xFFD9DBDF),
                    width: 1.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: imageBytes != null
                    ? Image.memory(
                        imageBytes,
                        width: 92,
                        height: 92,
                        fit: BoxFit.cover,
                      )
                    : const Icon(
                        Icons.person,
                        size: 45,
                        color: _charcoal,
                      ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: GestureDetector(
                  onTap: _showAvatarOptions,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _purple,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _pageBackground,
                        width: 2.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            userName.isEmpty ? 'Your Name' : userName,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: _charcoal,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Text(
            userJobTitle.isEmpty ? userRole : userJobTitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _softText,
            ),
            textAlign: TextAlign.center,
          ),
          if (userCompany.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              userCompany,
              style: const TextStyle(
                fontSize: 11,
                color: _mutedText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 9),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _green.withOpacity(0.20),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 7,
                  color: _green,
                ),
                SizedBox(width: 5),
                Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4F9A43),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // AVATAR OPTIONS
  // ==========================================================

  void _showAvatarOptions() {
    final bool hasImage = _profileImage != null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              4,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickProfileImage();
                  },
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _purple.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.upload_outlined,
                      size: 20,
                      color: _purple,
                    ),
                  ),
                  title: const Text(
                    'Upload Photo',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _charcoal,
                    ),
                  ),
                ),
                if (hasImage)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _removeProfileImage();
                    },
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _coral.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: _coral,
                      ),
                    ),
                    title: const Text(
                      'Remove Photo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _coral,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickProfileImage() async {
    final picked = await _profileImagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked == null) {
      return;
    }

    final bytes = await picked.readAsBytes();

    if (!mounted) return;

    setState(() {
      _profileImage = bytes;
      CurrentUser.profileImage = bytes;
    });
  }

  void _removeProfileImage() {
    setState(() {
      _profileImage = null;
      CurrentUser.profileImage = null;
    });
  }

  // ==========================================================
  // SECTION TITLE
  // ==========================================================

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: _charcoal,
      ),
    );
  }

  // ==========================================================
  // ACCOUNT OVERVIEW
  // ==========================================================

  Widget _buildAccountOverview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildOverviewMetric(
              icon: Icons.folder_outlined,
              iconColor: _blue,
              value: '6',
              label: 'Projects',
            ),
          ),
          _buildMetricDivider(),
          Expanded(
            child: _buildOverviewMetric(
              icon: Icons.task_alt_outlined,
              iconColor: _purple,
              value: '24',
              label: 'Tasks',
            ),
          ),
          _buildMetricDivider(),
          Expanded(
            child: _buildOverviewMetric(
              icon: Icons.check_circle_outline,
              iconColor: _green,
              value: '18',
              label: 'Completed',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewMetric({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: iconColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _charcoal,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: _mutedText,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricDivider() {
    return Container(
      width: 1,
      height: 58,
      color: const Color(0xFFE9EAED),
    );
  }

  // ==========================================================
  // PROFILE INFORMATION
  // ==========================================================

  Widget _buildProfileInformation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildProfileInfoRow(
            icon: Icons.person_outline,
            label: 'Full Name',
            value: userName,
          ),
          _buildProfileInfoDivider(),
          _buildProfileInfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: userEmail,
          ),
          _buildProfileInfoDivider(),
          _buildProfileInfoRow(
            icon: Icons.work_outline,
            label: 'Job Title',
            value: userJobTitle,
          ),
          _buildProfileInfoDivider(),
          _buildProfileInfoRow(
            icon: Icons.badge_outlined,
            label: 'Role',
            value: userRole,
          ),
          _buildProfileInfoDivider(),
          _buildProfileInfoRow(
            icon: Icons.business_outlined,
            label: 'Company / Organization',
            value: userCompany,
          ),
          _buildProfileInfoDivider(),
          _buildProfileInfoRow(
            icon: Icons.apartment_outlined,
            label: 'Department',
            value: userDepartment,
          ),
          _buildProfileInfoDivider(),
          _buildProfileInfoRow(
            icon: Icons.phone_outlined,
            label: 'Phone Number',
            value: userPhoneNumber.isEmpty ? 'Not provided' : userPhoneNumber,
          ),
          _buildProfileInfoDivider(),
          _buildProfileInfoRow(
            icon: Icons.public_outlined,
            label: 'Country',
            value: userCountry,
          ),
          _buildProfileInfoDivider(),
          _buildProfileInfoRow(
            icon: Icons.location_city_outlined,
            label: 'City',
            value: userCity,
          ),
          _buildProfileInfoDivider(),
          _buildProfileInfoRow(
            icon: Icons.dashboard_outlined,
            label: 'Default View',
            value: selectedDefaultView,
          ),
          if (userShortBio.isNotEmpty) ...[
            _buildProfileInfoDivider(),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Short Bio',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _mutedText,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                userShortBio,
                style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.45,
                  color: _softText,
                ),
              ),
            ),
          ],
          _buildProfileInfoDivider(),
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.notifications_none_outlined,
                  size: 18,
                  color: _green,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _charcoal,
                  ),
                ),
              ),
              Text(
                notificationsEnabled ? 'Enabled' : 'Disabled',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: notificationsEnabled ? _green : _mutedText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F5F7),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            icon,
            size: 18,
            color: _charcoal,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _mutedText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isEmpty ? 'Not provided' : value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _charcoal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfoDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 11,
      ),
      height: 1,
      color: const Color(0xFFEDEEF0),
    );
  }

  // ==========================================================
  // SETTING TILE
  // ==========================================================

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 11,
            ),
            child: Row(
              children: [
                Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F5F7),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    icon,
                    size: 19,
                    color: _charcoal,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _charcoal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                          color: _mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // NOTIFICATIONS
  // ==========================================================

  Future<void> _changeNotifications(
    bool value,
  ) async {
    if (_isSavingProfile) {
      return;
    }

    final oldValue = _notificationsEnabled;

    setState(() {
      _notificationsEnabled = value;
    });

    final success = await _updateProfile(
      fullName: _userName,
      jobTitle: _userJobTitle,
      company: _userCompany,
      department: _userDepartment,
      phone: _userPhoneNumber,
      country: _userCountry,
      city: _userCity,
      shortBio: _userShortBio,
      language: _userLanguage,
      defaultView: _selectedDefaultView,
      notificationsEnabled: value,
    );

    if (!success && mounted) {
      setState(() {
        _notificationsEnabled = oldValue;
      });
    }
  }

  // ==========================================================
  // TRAILING TEXT
  // ==========================================================

  Widget _buildTrailingText(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _mutedText,
          ),
        ),
        const SizedBox(width: 3),
        const Icon(
          Icons.chevron_right,
          size: 19,
          color: _mutedText,
        ),
      ],
    );
  }

  // ==========================================================
  // EDIT PROFILE
  // ==========================================================

  void _openEditProfile() {
    if (_isSavingProfile) {
      return;
    }

    final nameController = TextEditingController(text: _userName);

    final emailController = TextEditingController(text: _userEmail);

    final jobTitleController = TextEditingController(
      text: _userJobTitle,
    );

    final companyController = TextEditingController(
      text: _userCompany,
    );

    final departmentController = TextEditingController(
      text: _userDepartment,
    );

    final phoneController = TextEditingController(
      text: _userPhoneNumber,
    );

    final countryController = TextEditingController(
      text: _userCountry,
    );

    final cityController = TextEditingController(
      text: _userCity,
    );

    final bioController = TextEditingController(
      text: _userShortBio,
    );

    final String selectedRole = _userRole;

    String selectedDefaultViewValue = _selectedDefaultView;

    bool sheetNotifications = _notificationsEnabled;

    Uint8List? selectedImage = _profileImage;

    final imagePicker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                4,
                20,
                MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: _charcoal,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ------------------------------------------------
                    // PROFILE IMAGE
                    // ------------------------------------------------

                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 86,
                            height: 86,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(
                                0xFFE9EAED,
                              ),
                              border: Border.all(
                                color: const Color(
                                  0xFFD9DBDF,
                                ),
                                width: 1.5,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: selectedImage != null
                                ? Image.memory(
                                    selectedImage!,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 42,
                                    color: _charcoal,
                                  ),
                          ),
                          const SizedBox(height: 9),
                          TextButton.icon(
                            onPressed: () async {
                              final picked = await imagePicker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 85,
                              );

                              if (picked == null) {
                                return;
                              }

                              final bytes = await picked.readAsBytes();

                              setSheetState(() {
                                selectedImage = bytes;
                              });
                            },
                            icon: const Icon(
                              Icons.camera_alt_outlined,
                              size: 17,
                            ),
                            label: const Text(
                              'Change Photo',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: _purple,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ------------------------------------------------
                    // FULL NAME
                    // ------------------------------------------------

                    _buildInputField(
                      controller: nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                    ),

                    const SizedBox(height: 12),

                    // ------------------------------------------------
                    // EMAIL - READ ONLY
                    // ------------------------------------------------

                    _buildInputField(
                      controller: emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      readOnly: true,
                    ),

                    const SizedBox(height: 6),

                    const Padding(
                      padding: EdgeInsets.only(
                        left: 4,
                      ),
                      child: Text(
                        'Email is managed by your ScaleFlow account.',
                        style: TextStyle(
                          fontSize: 10,
                          color: _mutedText,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ------------------------------------------------
                    // JOB TITLE
                    // ------------------------------------------------

                    _buildInputField(
                      controller: jobTitleController,
                      label: 'Job Title',
                      icon: Icons.work_outline,
                    ),

                    const SizedBox(height: 12),

                    // ------------------------------------------------
                    // ROLE - READ ONLY
                    // ------------------------------------------------

                    _buildDropdownField(
                      label: 'Role',
                      value: selectedRole,
                      icon: Icons.badge_outlined,
                      items: const [
                        'Project Manager',
                        'Team Leader',
                        'Team Member',
                        'Client',
                      ],
                      onChanged: null,
                    ),

                    const SizedBox(height: 6),

                    const Padding(
                      padding: EdgeInsets.only(
                        left: 4,
                      ),
                      child: Text(
                        'Your system role is managed by ScaleFlow permissions.',
                        style: TextStyle(
                          fontSize: 10,
                          color: _mutedText,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ------------------------------------------------
                    // COMPANY
                    // ------------------------------------------------

                    _buildInputField(
                      controller: companyController,
                      label: 'Company / Organization',
                      icon: Icons.business_outlined,
                    ),

                    const SizedBox(height: 12),

                    // ------------------------------------------------
                    // DEPARTMENT
                    // ------------------------------------------------

                    _buildInputField(
                      controller: departmentController,
                      label: 'Department',
                      icon: Icons.apartment_outlined,
                    ),

                    const SizedBox(height: 12),

                    // ------------------------------------------------
                    // PHONE
                    // ------------------------------------------------

                    _buildInputField(
                      controller: phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                    ),

                    const SizedBox(height: 12),

                    // ------------------------------------------------
                    // COUNTRY
                    // ------------------------------------------------

                    _buildInputField(
                      controller: countryController,
                      label: 'Country',
                      icon: Icons.public_outlined,
                    ),

                    const SizedBox(height: 12),

                    // ------------------------------------------------
                    // CITY
                    // ------------------------------------------------

                    _buildInputField(
                      controller: cityController,
                      label: 'City',
                      icon: Icons.location_city_outlined,
                    ),

                    const SizedBox(height: 12),

                    // ------------------------------------------------
                    // BIO
                    // ------------------------------------------------

                    TextField(
                      controller: bioController,
                      maxLines: 4,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _charcoal,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Short Bio',
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          color: _mutedText,
                        ),
                        alignLabelWithHint: true,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(
                            bottom: 55,
                          ),
                          child: Icon(
                            Icons.notes_outlined,
                            size: 19,
                            color: _mutedText,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(
                          0xFFF9FAFB,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            11,
                          ),
                          borderSide: const BorderSide(
                            color: _border,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            11,
                          ),
                          borderSide: const BorderSide(
                            color: _border,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            11,
                          ),
                          borderSide: const BorderSide(
                            color: _purple,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ------------------------------------------------
                    // DEFAULT VIEW
                    // ------------------------------------------------

                    _buildDropdownField(
                      label: 'Default View',
                      value: selectedDefaultViewValue,
                      icon: Icons.dashboard_outlined,
                      items: const [
                        'Projects',
                        'Home',
                        'Tasks',
                        'AI Insights',
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setSheetState(() {
                          selectedDefaultViewValue = value;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    // ------------------------------------------------
                    // NOTIFICATIONS
                    // ------------------------------------------------

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFF9FAFB,
                        ),
                        borderRadius: BorderRadius.circular(
                          11,
                        ),
                        border: Border.all(
                          color: _border,
                        ),
                      ),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _charcoal,
                          ),
                        ),
                        subtitle: const Text(
                          'Receive important project updates.',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: _mutedText,
                          ),
                        ),
                        value: sheetNotifications,
                        activeColor: Colors.white,
                        activeTrackColor: _green,
                        onChanged: (value) {
                          setSheetState(() {
                            sheetNotifications = value;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ------------------------------------------------
                    // SAVE
                    // ------------------------------------------------

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSavingProfile
                            ? null
                            : () async {
                                final newName = nameController.text.trim();

                                if (newName.isEmpty) {
                                  _showMessage(
                                    'Full name is required.',
                                  );
                                  return;
                                }

                                Navigator.pop(
                                  sheetContext,
                                );

                                final success = await _updateProfile(
                                  fullName: newName,
                                  jobTitle: jobTitleController.text.trim(),
                                  company: companyController.text.trim(),
                                  department: departmentController.text.trim(),
                                  phone: phoneController.text.trim(),
                                  country: countryController.text.trim(),
                                  city: cityController.text.trim(),
                                  shortBio: bioController.text.trim(),
                                  language: _userLanguage,
                                  defaultView: selectedDefaultViewValue,
                                  notificationsEnabled: sheetNotifications,
                                );

                                if (!success) {
                                  return;
                                }

                                if (!mounted) {
                                  return;
                                }

                                // Avatar is still local.
                                setState(() {
                                  _profileImage = selectedImage;

                                  CurrentUser.profileImage = selectedImage;
                                });

                                _showMessage(
                                  'Profile updated successfully.',
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _purple,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _purple.withOpacity(
                            0.5,
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            vertical: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              11,
                            ),
                          ),
                        ),
                        child: _isSavingProfile
                            ? const SizedBox(
                                width: 19,
                                height: 19,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================================
  // INPUT FIELD
  // ==========================================================

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      style: TextStyle(
        fontSize: 13,
        color: readOnly ? _mutedText : _charcoal,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 12,
          color: _mutedText,
        ),
        prefixIcon: Icon(
          icon,
          size: 19,
          color: _mutedText,
        ),
        suffixIcon: readOnly
            ? const Icon(
                Icons.lock_outline,
                size: 16,
                color: _mutedText,
              )
            : null,
        filled: true,
        fillColor: readOnly ? const Color(0xFFF1F2F4) : const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(
            color: _border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(
            color: _border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(
            color: _purple,
            width: 1.4,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // DROPDOWN FIELD
  // ==========================================================

  Widget _buildDropdownField({
    required String label,
    required String value,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : items.first,
      isExpanded: true,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: _mutedText,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 12,
          color: _mutedText,
        ),
        prefixIcon: Icon(
          icon,
          size: 19,
          color: _mutedText,
        ),
        filled: true,
        fillColor: onChanged == null
            ? const Color(0xFFF1F2F4)
            : const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(
            color: _border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(
            color: _border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(
            color: _purple,
            width: 1.4,
          ),
        ),
      ),
      style: TextStyle(
        fontSize: 13,
        color: onChanged == null ? _mutedText : _charcoal,
        fontWeight: FontWeight.w500,
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  // ==========================================================
  // DEFAULT VIEW
  // ==========================================================

  void _openDefaultViewSettings() {
    if (_isSavingProfile) {
      return;
    }

    _showChoiceSheet(
      title: 'Default View',
      options: const [
        'Projects',
        'Home',
        'Tasks',
        'AI Insights',
      ],
      selectedValue: selectedDefaultView,
      onSelected: (value) async {
        final oldValue = _selectedDefaultView;

        setState(() {
          _selectedDefaultView = value;
        });

        final success = await _updateProfile(
          fullName: _userName,
          jobTitle: _userJobTitle,
          company: _userCompany,
          department: _userDepartment,
          phone: _userPhoneNumber,
          country: _userCountry,
          city: _userCity,
          shortBio: _userShortBio,
          language: _userLanguage,
          defaultView: value,
          notificationsEnabled: _notificationsEnabled,
        );

        if (!success && mounted) {
          setState(() {
            _selectedDefaultView = oldValue;
          });
        }
      },
    );
  }

  // ==========================================================
  // GENERIC CHOICE SHEET
  // ==========================================================

  void _showChoiceSheet({
    required String title,
    required List<String> options,
    required String selectedValue,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              4,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: _charcoal,
                  ),
                ),
                const SizedBox(height: 12),
                ...options.map((option) {
                  final selected = option == selectedValue;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () {
                      onSelected(option);
                      Navigator.pop(
                        sheetContext,
                      );
                    },
                    title: Text(
                      option,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: _charcoal,
                      ),
                    ),
                    trailing: Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: selected ? _purple : _mutedText,
                      size: 20,
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // LOGOUT BUTTON
  // ==========================================================

  Widget _buildLogOutButton() {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showLogoutDialog,
          borderRadius: BorderRadius.circular(11),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: _coral.withOpacity(0.06),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: _coral.withOpacity(0.20),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout,
                  size: 18,
                  color: Color(0xFFE15C3E),
                ),
                SizedBox(width: 8),
                Text(
                  'Log Out',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE15C3E),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // SETTINGS
  // ==========================================================

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              4,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: _charcoal,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSheetOption(
                  icon: Icons.notifications_none_outlined,
                  title: 'Notifications',
                  subtitle: notificationsEnabled ? 'Enabled' : 'Disabled',
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                    );
                    _changeNotifications(
                      !notificationsEnabled,
                    );
                  },
                ),
                _buildSheetOption(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy & Data',
                  subtitle: 'Manage your preferences',
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                    );
                    _openPrivacySettings();
                  },
                ),
                _buildSheetOption(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  subtitle: 'Get help with ScaleFlow',
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                    );
                    _openHelpSupport();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F5F7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: _charcoal,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _charcoal,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 10.5,
          color: _mutedText,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: _mutedText,
      ),
    );
  }

  // ==========================================================
  // PASSWORD & SECURITY
  // ==========================================================

  void _openPasswordSecurity() {
    final currentPasswordController = TextEditingController();

    final newPasswordController = TextEditingController();

    final confirmPasswordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Password & Security',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: _charcoal,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Update your password to keep your account secure.',
                  style: TextStyle(
                    fontSize: 11,
                    color: _mutedText,
                  ),
                ),
                const SizedBox(height: 18),
                _buildPasswordField(
                  controller: currentPasswordController,
                  label: 'Current Password',
                ),
                const SizedBox(height: 11),
                _buildPasswordField(
                  controller: newPasswordController,
                  label: 'New Password',
                ),
                const SizedBox(height: 11),
                _buildPasswordField(
                  controller: confirmPasswordController,
                  label: 'Confirm Password',
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (newPasswordController.text.isEmpty ||
                          newPasswordController.text !=
                              confirmPasswordController.text) {
                        return;
                      }

                      Navigator.pop(
                        sheetContext,
                      );

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Password updated successfully.',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _purple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          11,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Update Password',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      obscureText: true,
      style: const TextStyle(
        fontSize: 13,
        color: _charcoal,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 12,
          color: _mutedText,
        ),
        prefixIcon: const Icon(
          Icons.lock_outline,
          size: 19,
          color: _mutedText,
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(
            color: _border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(
            color: _border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(
            color: _purple,
            width: 1.4,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // PRIVACY & DATA
  // ==========================================================

  void _openPrivacySettings() {
    bool activityVisible = true;
    bool analyticsEnabled = true;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  4,
                  20,
                  24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Privacy & Data',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: _charcoal,
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Activity Visibility',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _charcoal,
                        ),
                      ),
                      subtitle: const Text(
                        'Allow team members to see your activity.',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: _mutedText,
                        ),
                      ),
                      value: activityVisible,
                      activeColor: Colors.white,
                      activeTrackColor: _green,
                      onChanged: (value) {
                        setSheetState(() {
                          activityVisible = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Usage Analytics',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _charcoal,
                        ),
                      ),
                      subtitle: const Text(
                        'Help improve ScaleFlow with usage data.',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: _mutedText,
                        ),
                      ),
                      value: analyticsEnabled,
                      activeColor: Colors.white,
                      activeTrackColor: _cyan,
                      onChanged: (value) {
                        setSheetState(() {
                          analyticsEnabled = value;
                        });
                      },
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        Navigator.pop(
                          sheetContext,
                        );

                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Data export request created.',
                            ),
                          ),
                        );
                      },
                      leading: const Icon(
                        Icons.download_outlined,
                        color: _charcoal,
                      ),
                      title: const Text(
                        'Export My Data',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _charcoal,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: _mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================================
  // HELP & SUPPORT
  // ==========================================================

  void _openHelpSupport() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              4,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Help & Support',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: _charcoal,
                  ),
                ),
                const SizedBox(height: 14),
                _buildSheetOption(
                  icon: Icons.menu_book_outlined,
                  title: 'Help Center',
                  subtitle: 'Browse ScaleFlow help articles',
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                    );
                    _showComingSoon(
                      'Help Center',
                    );
                  },
                ),
                _buildSheetOption(
                  icon: Icons.chat_bubble_outline,
                  title: 'Contact Support',
                  subtitle: 'Send a message to the support team',
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                    );
                    _showComingSoon(
                      'Contact Support',
                    );
                  },
                ),
                _buildSheetOption(
                  icon: Icons.bug_report_outlined,
                  title: 'Report a Problem',
                  subtitle: 'Tell us about an issue',
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                    );
                    _showComingSoon(
                      'Report a Problem',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature is ready for backend integration.',
        ),
      ),
    );
  }

  // ==========================================================
  // LOGOUT DIALOG
  // ==========================================================

  void _showLogoutDialog() {
    final profileContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Log Out',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _charcoal,
            ),
          ),
          content: const Text(
            'Are you sure you want to log out?',
            style: TextStyle(
              color: _softText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: _softText,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );

                // Clear the real JWT.
                AuthService.logout();

                // Clear local cache.
                CurrentUser.logout();

                if (!mounted) return;

                Navigator.of(
                  profileContext,
                ).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              },
              child: const Text(
                'Log Out',
                style: TextStyle(
                  color: _coral,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
