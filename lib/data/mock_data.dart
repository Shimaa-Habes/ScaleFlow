import '../core/app_colors.dart';
import '../models/project.dart';
import '../models/task_item.dart';

// ============================================================
// TODO (Backend track): كل شي بهالملف mock/static بس، حسب متطلبات
// التاسك ("Use mock/static data where needed. Keep the implementation
// ready for future Backend/API integration."). لما يجهز الـ API:
// - CurrentUser.register()/login() → لازم تصير نداء حقيقي لـ
//   POST /api/auth/register و POST /api/auth/login بدل التخزين
//   المحلي بالذاكرة هون.
// - MockData.projects → لازم تتحول لنداء GET /api/projects
// كل الشاشات بتستهلك هاي القيم من هون بس، فالتبديل بصير بمكان واحد.
// ============================================================

/// حساب مستخدم وهمي (mock) — بس بالذاكرة، بينمسح لما تسكّري التطبيق.
/// هاد بديل مؤقت لقاعدة بيانات حقيقية لحد ما يجهز الـ Backend.
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

/// المستخدم الحالي — هلأ ديناميكي فعلياً:
/// - `register()` بتحفظ أي حساب جديد تعمليه فعلياً بالذاكرة
/// - `login()` بتتحقق من الإيميل/كلمة السر مقابل الحسابات المحفوظة
/// - `firstName` (المستخدم بشاشة الـ Home) بيرجع دايماً اسم آخر مستخدم
///   سجّل دخول أو أنشأ حساب بنجاح — مش اسم ثابت
class CurrentUser {
  // حساب تجريبي جاهز مسبقاً، تقدري تسجّلي فيه دخول مباشرة بدون تسجيل:
  // Email: test@scaleflow.com — Password: Test1234
  static final List<_MockAccount> _accounts = [
    const _MockAccount(
      fullName: 'Shimaa Ahmad',
      email: 'test@scaleflow.com',
      password: 'Test1234',
    ),
  ];

  static String fullName = 'Shimaa Ahmad';

  /// بيرجع أول اسم بس من الاسم الكامل، لعرض التحية
  /// ("Good morning, Lama 👋" مثلاً) — بيتحدث تلقائياً حسب آخر
  /// تسجيل دخول أو تسجيل حساب ناجح
  static String get firstName {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  /// بتضيف حساب جديد فعلياً للقائمة وبتخليه هو المستخدم الحالي —
  /// هاي اللي كانت ناقصة وسببت مشكلة "الإيميل وكلمة السر صح بس بيقول غلط"
  static void register({
    required String fullName,
    required String email,
    required String password,
  }) {
    _accounts.add(_MockAccount(
      fullName: fullName,
      email: email,
      password: password,
    ));
    CurrentUser.fullName = fullName;
  }

  /// بتدوّر على حساب متطابق بالإيميل وكلمة السر بالضبط.
  /// إذا لقت تطابق: بتحدّث المستخدم الحالي وترجع true.
  /// إذا ما لقت: بترجع false (فبتظهر "Invalid email or password").
  static bool login({
    required String email,
    required String password,
  }) {
    for (final account in _accounts) {
      if (account.email.trim().toLowerCase() ==
              email.trim().toLowerCase() &&
          account.password == password) {
        CurrentUser.fullName = account.fullName;
        return true;
      }
    }
    return false;
  }
}


class MockData {
  MockData._();

  static final List<Project> projects = [
    Project(
      id: 'website-redesign',
      name: 'Website Redesign',
      subtitle: 'Client Portal & Web Experience',
      status: ProjectStatus.onTrack,
      percentComplete: 72,
      dueDate: 'Due Sep 28, 2026',
      healthPercent: 84,
      healthNote: 'Progress is on track with current deadlines.',
      teamCount: 8,
      tasksCompleted: 24,
      tasksTotal: 34,
      daysLeft: 14,
      aiInsightTitle: 'ScaleFlow AI Insight',
      aiInsightBody:
          'API Integration is currently the main bottleneck and may affect the next milestone.',
      team: const [
        TeamMember(initials: 'AM', color: AppColors.usersPink),
        TeamMember(initials: 'RK', color: AppColors.dataCyan),
        TeamMember(initials: 'JT', color: AppColors.aiPurple),
        TeamMember(initials: 'SL', color: AppColors.statusGreen),
      ],
      tasks: const [
        TaskItem(
          id: 't1',
          title: 'Finalize API Integration',
          dueLabel: 'Due Today',
          urgency: TaskUrgency.dueToday,
        ),
        TaskItem(
          id: 't2',
          title: 'Review UI Components',
          dueLabel: 'Due Tomorrow',
          urgency: TaskUrgency.dueSoon,
        ),
        TaskItem(
          id: 't3',
          title: 'Client Testing',
          dueLabel: 'Due Sep 18',
          urgency: TaskUrgency.upcoming,
        ),
      ],
    ),
    Project(
      id: 'mobile-app-launch',
      name: 'Mobile App Launch',
      subtitle: 'iOS & Android release',
      status: ProjectStatus.atRisk,
      percentComplete: 58,
      dueDate: 'Due Oct 10, 2026',
      healthPercent: 61,
      healthNote: 'A few tasks are slipping behind schedule.',
      teamCount: 6,
      tasksCompleted: 15,
      tasksTotal: 26,
      daysLeft: 26,
      aiInsightTitle: 'ScaleFlow AI Insight',
      aiInsightBody:
          'App Store review delays may push the launch date by up to a week.',
      team: const [
        TeamMember(initials: 'MZ', color: AppColors.alertCoral),
        TeamMember(initials: 'HB', color: AppColors.dataCyan),
        TeamMember(initials: 'QF', color: AppColors.usersPink),
      ],
      tasks: const [
        TaskItem(
          id: 't4',
          title: 'Fix crash on onboarding',
          dueLabel: 'Due Today',
          urgency: TaskUrgency.dueToday,
        ),
        TaskItem(
          id: 't5',
          title: 'Prepare App Store listing',
          dueLabel: 'Due Sep 20',
          urgency: TaskUrgency.upcoming,
        ),
      ],
    ),
    Project(
      id: 'client-portal',
      name: 'Client Portal',
      subtitle: 'Self-service dashboard for clients',
      status: ProjectStatus.onTrack,
      percentComplete: 81,
      dueDate: 'Due Sep 20, 2026',
      healthPercent: 90,
      healthNote: 'Ahead of schedule and well within scope.',
      teamCount: 5,
      tasksCompleted: 29,
      tasksTotal: 34,
      daysLeft: 6,
      aiInsightTitle: 'ScaleFlow AI Insight',
      aiInsightBody:
          'Current velocity suggests an early finish — consider pulling in QA sooner.',
      team: const [
        TeamMember(initials: 'NA', color: AppColors.statusGreen),
        TeamMember(initials: 'DP', color: AppColors.aiPurple),
      ],
      tasks: const [
        TaskItem(
          id: 't6',
          title: 'Prepare Client Report',
          dueLabel: 'Due Sep 15',
          urgency: TaskUrgency.upcoming,
        ),
      ],
    ),
  ];

  /// أرقام "Today's Overview" أعلى شاشة الـ Home — مأخوذة كقيم ثابتة
  /// مطابقة للتصميم (بدل ما نحسبها من المشاريع، لأنو التصميم بيعرض
  /// أرقام على مستوى كل المنظمة مش مشروع واحد فقط)
  static const int activeProjects = 6;
  static const int tasksDue = 18;
  static const int overdueTasks = 7;
  static const int atRiskCount = 2;
  static const int overallHealthPercent = 84;
  static const String overallHealthTrend = '+6% compared with last week';

  /// كل المهام ذات الأولوية عبر كل المشاريع (Priority Tasks بشاشة الـ Home)
  static List<TaskItem> get priorityTasks => [
        projects[0].tasks[0],
        projects[0].tasks[1],
        projects[2].tasks[0],
      ];
}
