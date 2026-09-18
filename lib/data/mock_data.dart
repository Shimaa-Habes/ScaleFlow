import 'dart:typed_data';

import '../core/app_colors.dart';
import '../models/project.dart';
import '../models/task_item.dart';

class _MockAccount {
  final String fullName;
  final String email;
  final String password;

  const _MockAccount({
    required this.fullName,
    required this.email,
    required this.password,
  });
}

class CurrentUser {
  static final List<_MockAccount> _accounts = [
    const _MockAccount(
      fullName: 'Shimaa Ahmad',
      email: 'test@scaleflow.com',
      password: 'Test1234',
    ),
  ];

  // ============================================================
  // BASIC ACCOUNT DATA
  // ============================================================

  static String fullName = 'Shimaa Ahmad';
  static String email = 'test@scaleflow.com';

  static String get firstName {
    final trimmed = fullName.trim();

    if (trimmed.isEmpty) {
      return '';
    }

    return trimmed.split(RegExp(r'\s+')).first;
  }

  // ============================================================
  // COMPLETE PROFILE DATA
  // ============================================================

  static Uint8List? profileImage;

  static String jobTitle = 'Junior Full-Stack Developer';
  static String role = 'Team Leader';
  static String company = 'BinX Tech';
  static String department = 'AI/ML';
  static String phoneNumber = '';
  static String country = 'Palestine';
  static String city = 'Dura';

  static String shortBio =
      'Junior Full-Stack Developer interested in AI/ML and modern web development.';

  static String language = 'English';
  static String defaultView = 'Projects';
  static bool notificationsEnabled = true;

  // ============================================================
  // REGISTER
  // ============================================================

  static void register({
    required String fullName,
    required String email,
    required String password,
  }) {
    _accounts.add(
      _MockAccount(
        fullName: fullName,
        email: email,
        password: password,
      ),
    );

    CurrentUser.fullName = fullName;
    CurrentUser.email = email;
  }

  // ============================================================
  // LOGIN
  // ============================================================

  static bool login({
    required String email,
    required String password,
  }) {
    for (final account in _accounts) {
      if (account.email.trim().toLowerCase() == email.trim().toLowerCase() &&
          account.password == password) {
        CurrentUser.fullName = account.fullName;
        CurrentUser.email = account.email;

        return true;
      }
    }

    return false;
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  static void logout() {
    CurrentUser.fullName = '';
    CurrentUser.email = '';
  }
}

// ================================================================
// SCALEFLOW PROJECTS
// ================================================================

final List<Project> scaleFlowProjects = [
  // ============================================================
  // 1. WEBSITE REDESIGN
  // ============================================================

  Project(
    id: 'website-redesign',
    name: 'Website Redesign',
    subtitle: 'Redesign the company website and improve user experience.',
    status: ProjectStatus.onTrack,
    percentComplete: 72,
    dueDate: 'Sep 28, 2026',
    healthPercent: 84,
    healthNote: 'Project is progressing well with minor dependency risks.',
    teamCount: 6,
    tasksCompleted: 18,
    tasksTotal: 25,
    daysLeft: 10,
    aiInsightTitle: 'AI Recommendation',
    aiInsightBody: 'Website Redesign may be delayed by API Integration.',
    team: [
      TeamMember(
        initials: 'SH',
        color: AppColors.usersPink,
      ),
      TeamMember(
        initials: 'SA',
        color: AppColors.dataCyan,
      ),
      TeamMember(
        initials: 'SF',
        color: AppColors.statusGreen,
      ),
      TeamMember(
        initials: 'MA',
        color: AppColors.priorityYellow,
      ),
    ],
    tasks: [
      TaskItem(
        id: 'finalize-api-integration',
        title: 'Finalize API Integration',
        dueLabel: 'Due Today',
        urgency: TaskUrgency.dueToday,
      ),
      TaskItem(
        id: 'review-ui-components',
        title: 'Review UI Components',
        dueLabel: 'Due Tomorrow',
        urgency: TaskUrgency.dueSoon,
      ),
      TaskItem(
        id: 'prepare-client-report',
        title: 'Prepare Client Report',
        dueLabel: 'Due Sep 20',
        urgency: TaskUrgency.upcoming,
      ),
    ],
  ),

  // ============================================================
  // 2. MOBILE APP LAUNCH
  // ============================================================

  Project(
    id: 'mobile-app-launch',
    name: 'Mobile App Launch',
    subtitle: 'Prepare the mobile application for release.',
    status: ProjectStatus.atRisk,
    percentComplete: 58,
    dueDate: 'Oct 5, 2026',
    healthPercent: 61,
    healthNote: 'Some tasks are behind schedule and need attention.',
    teamCount: 5,
    tasksCompleted: 14,
    tasksTotal: 24,
    daysLeft: 17,
    aiInsightTitle: 'AI Recommendation',
    aiInsightBody:
        'Mobile App Launch has an increased risk of delay due to pending tasks.',
    team: [
      TeamMember(
        initials: 'SH',
        color: AppColors.usersPink,
      ),
      TeamMember(
        initials: 'LW',
        color: AppColors.dataCyan,
      ),
      TeamMember(
        initials: 'MW',
        color: AppColors.statusGreen,
      ),
      TeamMember(
        initials: 'MA',
        color: AppColors.alertCoral,
      ),
    ],
    tasks: [
      TaskItem(
        id: 'complete-authentication-flow',
        title: 'Complete Authentication Flow',
        dueLabel: 'Due Sep 20',
        urgency: TaskUrgency.dueToday,
      ),
      TaskItem(
        id: 'review-mobile-navigation',
        title: 'Review Mobile Navigation',
        dueLabel: 'Due Sep 22',
        urgency: TaskUrgency.dueSoon,
      ),
      TaskItem(
        id: 'prepare-release-build',
        title: 'Prepare Release Build',
        dueLabel: 'Due Sep 25',
        urgency: TaskUrgency.upcoming,
      ),
    ],
  ),

  // ============================================================
  // 3. CLIENT PORTAL
  // ============================================================

  Project(
    id: 'client-portal',
    name: 'Client Portal',
    subtitle: 'Build a secure portal for client project access.',
    status: ProjectStatus.onTrack,
    percentComplete: 81,
    dueDate: 'Sep 25, 2026',
    healthPercent: 89,
    healthNote: 'The project is progressing steadily toward completion.',
    teamCount: 4,
    tasksCompleted: 21,
    tasksTotal: 26,
    daysLeft: 7,
    aiInsightTitle: 'AI Recommendation',
    aiInsightBody:
        'Client Portal is progressing steadily with no major risks detected.',
    team: [
      TeamMember(
        initials: 'SH',
        color: AppColors.usersPink,
      ),
      TeamMember(
        initials: 'SA',
        color: AppColors.dataCyan,
      ),
      TeamMember(
        initials: 'MW',
        color: AppColors.statusGreen,
      ),
    ],
    tasks: [
      TaskItem(
        id: 'complete-client-dashboard',
        title: 'Complete Client Dashboard',
        dueLabel: 'Due Tomorrow',
        urgency: TaskUrgency.dueSoon,
      ),
      TaskItem(
        id: 'review-access-permissions',
        title: 'Review Access Permissions',
        dueLabel: 'Due Sep 20',
        urgency: TaskUrgency.upcoming,
      ),
    ],
  ),

  // ============================================================
  // 4. MARKETING CAMPAIGN
  // ============================================================

  Project(
    id: 'marketing-campaign',
    name: 'Marketing Campaign',
    subtitle: 'Plan and monitor the upcoming marketing campaign.',
    status: ProjectStatus.onTrack,
    percentComplete: 67,
    dueDate: 'Oct 2, 2026',
    healthPercent: 76,
    healthNote: 'Campaign activities are progressing according to plan.',
    teamCount: 5,
    tasksCompleted: 16,
    tasksTotal: 24,
    daysLeft: 14,
    aiInsightTitle: 'AI Recommendation',
    aiInsightBody:
        'Marketing Campaign is progressing normally with no critical issues.',
    team: [
      TeamMember(
        initials: 'SH',
        color: AppColors.usersPink,
      ),
      TeamMember(
        initials: 'SF',
        color: AppColors.dataCyan,
      ),
      TeamMember(
        initials: 'LW',
        color: AppColors.statusGreen,
      ),
    ],
    tasks: [
      TaskItem(
        id: 'prepare-campaign-content',
        title: 'Prepare Campaign Content',
        dueLabel: 'Due Sep 21',
        urgency: TaskUrgency.upcoming,
      ),
      TaskItem(
        id: 'review-campaign-plan',
        title: 'Review Campaign Plan',
        dueLabel: 'Due Sep 23',
        urgency: TaskUrgency.upcoming,
      ),
    ],
  ),
];
