import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/mock_data.dart';
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
  String get userName => CurrentUser.fullName;

  String get userEmail => CurrentUser.email;

  String get userJobTitle => CurrentUser.jobTitle;

  String get userRole => CurrentUser.role;

  String get userCompany => CurrentUser.company;

  String get userDepartment => CurrentUser.department;

  String get userPhoneNumber => CurrentUser.phoneNumber;

  String get userCountry => CurrentUser.country;

  String get userCity => CurrentUser.city;

  String get userShortBio => CurrentUser.shortBio;

  String get selectedDefaultView => CurrentUser.defaultView;

  bool get notificationsEnabled => CurrentUser.notificationsEnabled;

  // String selectedAppearance = 'Light Mode';

  // A dedicated ImagePicker instance reused by both the avatar's
  // quick upload/remove button and the full Edit Profile sheet.
  final ImagePicker _profileImagePicker = ImagePicker();

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
              child: SingleChildScrollView(
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
                    _buildSectionTitle('Account Overview'),
                    const SizedBox(height: 10),
                    _buildAccountOverview(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Profile Information'),
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
                        onChanged: (value) {
                          setState(() {
                            CurrentUser.notificationsEnabled = value;
                          });
                        },
                        activeColor: Colors.white,
                        activeTrackColor: _green,
                      ),
                      onTap: () {
                        setState(() {
                          CurrentUser.notificationsEnabled =
                              !CurrentUser.notificationsEnabled;
                        });
                      },
                    ),
                    // _buildSettingTile(
                    //   icon: Icons.palette_outlined,
                    //   title: 'Appearance',
                    //   subtitle: selectedAppearance,
                    //   trailing: const Icon(
                    //     Icons.chevron_right,
                    //     size: 20,
                    //     color: _mutedText,
                    //   ),
                    //   onTap: _openAppearanceSettings,
                    // ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Preferences'),
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
                    _buildSectionTitle('Security & Privacy'),
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
          // index == 4 is Profile, so we do nothing.
        },
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
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

  // ============================================================
  // PROFILE HEADER
  // The avatar now carries its own small camera button (bottom
  // right) so the user can upload or remove a profile photo
  // directly from this screen, independent of any avatar shown
  // elsewhere (e.g. the Home screen) — this photo is stored only
  // in CurrentUser.profileImage and nowhere else.
  // ============================================================

  Widget _buildProfileHeader() {
    final Uint8List? imageBytes = CurrentUser.profileImage;

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

              // ------------------------------------------------
              // Camera / upload-remove button
              // ------------------------------------------------
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

  // ============================================================
  // AVATAR OPTIONS (upload / remove)
  // Opens a small action sheet with "Upload Photo" always shown,
  // and "Remove Photo" shown only when a photo is already set.
  // ============================================================

  void _showAvatarOptions() {
    final bool hasImage = CurrentUser.profileImage != null;

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
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
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

    setState(() {
      CurrentUser.profileImage = bytes;
    });
  }

  void _removeProfileImage() {
    setState(() {
      CurrentUser.profileImage = null;
    });
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

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

  // ============================================================
  // ACCOUNT OVERVIEW
  // ============================================================

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

  // ============================================================
  // PROFILE INFORMATION
  // ============================================================

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
      margin: const EdgeInsets.symmetric(vertical: 11),
      height: 1,
      color: const Color(0xFFEDEEF0),
    );
  }

  // ============================================================
  // SETTING TILE
  // ============================================================

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

  // ============================================================
  // TRAILING TEXT
  // ============================================================

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

  // ============================================================
  // LOG OUT
  // ============================================================

  Widget _buildLogOutButton() {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showLogoutDialog,
          borderRadius: BorderRadius.circular(11),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
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

  // ============================================================
  // SETTINGS
  // ============================================================

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
                    Navigator.pop(sheetContext);

                    setState(() {
                      CurrentUser.notificationsEnabled =
                          !CurrentUser.notificationsEnabled;
                    });
                  },
                ),
                // _buildSheetOption(
                //   icon: Icons.palette_outlined,
                //   title: 'Appearance',
                //   subtitle: selectedAppearance,
                //   onTap: () {
                //     Navigator.pop(sheetContext);
                //     _openAppearanceSettings();
                //   },
                // ),
                _buildSheetOption(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy & Data',
                  subtitle: 'Manage your preferences',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openPrivacySettings();
                  },
                ),
                _buildSheetOption(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  subtitle: 'Get help with ScaleFlow',
                  onTap: () {
                    Navigator.pop(sheetContext);
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

  // ============================================================
  // EDIT PROFILE
  // ============================================================

  void _openEditProfile() {
    final nameController = TextEditingController(text: CurrentUser.fullName);

    final emailController = TextEditingController(text: CurrentUser.email);

    final jobTitleController =
        TextEditingController(text: CurrentUser.jobTitle);

    final companyController = TextEditingController(text: CurrentUser.company);

    final departmentController =
        TextEditingController(text: CurrentUser.department);

    final phoneController =
        TextEditingController(text: CurrentUser.phoneNumber);

    final countryController = TextEditingController(text: CurrentUser.country);

    final cityController = TextEditingController(text: CurrentUser.city);

    final bioController = TextEditingController(text: CurrentUser.shortBio);

    String selectedRole = CurrentUser.role;
    String selectedDefaultViewValue = CurrentUser.defaultView;

    bool sheetNotifications = CurrentUser.notificationsEnabled;

    Uint8List? selectedImage = CurrentUser.profileImage;

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
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 86,
                            height: 86,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFE9EAED),
                              border: Border.all(
                                color: const Color(0xFFD9DBDF),
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
                    _buildInputField(
                      controller: nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: jobTitleController,
                      label: 'Job Title',
                      icon: Icons.work_outline,
                    ),
                    const SizedBox(height: 12),
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
                      onChanged: (value) {
                        if (value == null) return;

                        setSheetState(() {
                          selectedRole = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: companyController,
                      label: 'Company / Organization',
                      icon: Icons.business_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: departmentController,
                      label: 'Department',
                      icon: Icons.apartment_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: countryController,
                      label: 'Country',
                      icon: Icons.public_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: cityController,
                      label: 'City',
                      icon: Icons.location_city_outlined,
                    ),
                    const SizedBox(height: 12),
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
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 12),
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
                        if (value == null) return;

                        setSheetState(() {
                          selectedDefaultViewValue = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: _border),
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
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final newName = nameController.text.trim();

                          final newEmail = emailController.text.trim();

                          if (newName.isEmpty || newEmail.isEmpty) {
                            return;
                          }

                          setState(() {
                            CurrentUser.fullName = newName;
                            CurrentUser.email = newEmail;

                            CurrentUser.jobTitle =
                                jobTitleController.text.trim();

                            CurrentUser.role = selectedRole;

                            CurrentUser.company = companyController.text.trim();

                            CurrentUser.department =
                                departmentController.text.trim();

                            CurrentUser.phoneNumber =
                                phoneController.text.trim();

                            CurrentUser.country = countryController.text.trim();

                            CurrentUser.city = cityController.text.trim();

                            CurrentUser.shortBio = bioController.text.trim();

                            CurrentUser.defaultView = selectedDefaultViewValue;

                            CurrentUser.notificationsEnabled =
                                sheetNotifications;

                            CurrentUser.profileImage = selectedImage;
                          });

                          Navigator.pop(sheetContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _purple,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            vertical: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        child: const Text(
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

  // ============================================================
  // INPUT FIELD
  // ============================================================

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        fontSize: 13,
        color: _charcoal,
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

  // ============================================================
  // DROPDOWN FIELD
  // ============================================================

  Widget _buildDropdownField({
    required String label,
    required String value,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
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
      style: const TextStyle(
        fontSize: 13,
        color: _charcoal,
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

  // ============================================================
  // APPEARANCE
  // ============================================================

  // void _openAppearanceSettings() {
  //   _showChoiceSheet(
  //     title: 'Appearance',
  //     options: const [
  //       'Light Mode',
  //       'Dark Mode',
  //     ],
  //     selectedValue: selectedAppearance,
  //     onSelected: (value) {
  //       setState(() {
  //         selectedAppearance = value;
  //       });
  //     },
  //   );
  // }

  // ============================================================
  // DEFAULT VIEW
  // ============================================================

  void _openDefaultViewSettings() {
    _showChoiceSheet(
      title: 'Default View',
      options: const [
        'Projects',
        'Home',
        'Tasks',
        'AI Insights',
      ],
      selectedValue: selectedDefaultView,
      onSelected: (value) {
        setState(() {
          CurrentUser.defaultView = value;
        });
      },
    );
  }

  // ============================================================
  // GENERIC CHOICE SHEET
  // ============================================================

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
                  final bool selected = option == selectedValue;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () {
                      onSelected(option);
                      Navigator.pop(sheetContext);
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

  // ============================================================
  // PASSWORD & SECURITY
  // ============================================================

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

                      Navigator.pop(sheetContext);

                      ScaffoldMessenger.of(context).showSnackBar(
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
                        borderRadius: BorderRadius.circular(11),
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

  // ============================================================
  // PRIVACY & DATA
  // ============================================================

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
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        Navigator.pop(sheetContext);

                        ScaffoldMessenger.of(context).showSnackBar(
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

  // ============================================================
  // HELP & SUPPORT
  // ============================================================

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
                    Navigator.pop(sheetContext);
                    _showComingSoon('Help Center');
                  },
                ),
                _buildSheetOption(
                  icon: Icons.chat_bubble_outline,
                  title: 'Contact Support',
                  subtitle: 'Send a message to the support team',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showComingSoon('Contact Support');
                  },
                ),
                _buildSheetOption(
                  icon: Icons.bug_report_outlined,
                  title: 'Report a Problem',
                  subtitle: 'Tell us about an issue',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showComingSoon('Report a Problem');
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

  // ============================================================
  // LOGOUT DIALOG
  // ============================================================

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
                Navigator.pop(dialogContext);
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
                Navigator.pop(dialogContext);

                CurrentUser.logout();

                if (!mounted) return;

                Navigator.of(profileContext).pushNamedAndRemoveUntil(
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
