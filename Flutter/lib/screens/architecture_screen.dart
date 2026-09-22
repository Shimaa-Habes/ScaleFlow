import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../widgets/scaleflow_bottom_nav.dart';
import 'ai_insights_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'projects_screen.dart';

class ArchitecturePage extends StatelessWidget {
  const ArchitecturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.background,

        // ============================================================
        // BOTTOM NAVIGATION
        // ============================================================

        bottomNavigationBar: ScaleFlowBottomNav(
          currentIndex: 1,
          onTap: (index) {
            if (index == 0) {
              Navigator.of(context).pop();
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
            } else if (index == 4) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
            }
          },
        ),

        // ============================================================
        // BODY
        // ============================================================

        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth =
                  constraints.maxWidth < 600 ? constraints.maxWidth : 460.0;

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: maxWidth,
                    ),
                    child: Column(
                      children: [
                        _buildTopBar(context),

                        const SizedBox(height: 4),

                        const Text(
                          'Architecture',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkCharcoal,
                          ),
                        ),

                        const SizedBox(height: 4),

                        const Text(
                          'How ScaleFlow connects projects, data, AI, and users.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),

                        const SizedBox(height: 13),

                        // ==================================================
                        // LAYER 1 — USER APPLICATIONS
                        // Same size as the Layer 4 cards below, and text is
                        // centered both horizontally and vertically.
                        // ==================================================

                        const _LayerTitle(
                          text: 'Layer 1 — User Applications',
                        ),

                        const SizedBox(height: 7),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            _CornerCard(
                              color: AppColors.usersPink,
                              icon: Icons.phone_android_outlined,
                              title: 'Mobile App',
                              lines: ['Flutter'],
                              width: 130,
                              height: 100,
                            ),
                            SizedBox(width: 8),
                            _CornerCard(
                              color: AppColors.dataCyan,
                              icon: Icons.web_outlined,
                              title: 'Web App',
                              lines: ['Next.js'],
                              width: 130,
                              height: 100,
                            ),
                          ],
                        ),

                        const _VerticalConnector(),

                        // ==================================================
                        // LAYER 2 — BACKEND API
                        // ==================================================

                        const _LayerTitle(
                          text: 'Layer 2 — Backend API',
                        ),

                        const SizedBox(height: 7),

                        const _BackendCard(),

                        const _VerticalConnector(),

                        // ==================================================
                        // LAYER 3 — DATA
                        // ==================================================

                        const _LayerTitle(
                          text: 'Layer 3 — Data',
                        ),

                        const SizedBox(height: 7),

                        const _DataCard(),

                        const _VerticalConnector(),

                        // ==================================================
                        // LAYER 4 — AI & INTELLIGENCE
                        // Same _CornerCard used above, so both rows share
                        // identical width/height and centered text.
                        // ==================================================

                        const _LayerTitle(
                          text: 'Layer 4 — AI & Intelligence',
                        ),

                        const SizedBox(height: 7),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            _CornerCard(
                              color: AppColors.aiPurple,
                              icon: Icons.auto_awesome,
                              title: 'AI / ML Engine',
                              lines: [
                                'Delay Prediction',
                                'Risk Scoring',
                                'Bottleneck Detection',
                                'Workload Analysis',
                              ],
                            ),
                            SizedBox(width: 8),
                            _CornerCard(
                              color: AppColors.priorityYellow,
                              icon: Icons.psychology_outlined,
                              title: 'Generative AI',
                              lines: [
                                'Executive Summaries',
                                'Recommendations',
                                'Project Reports',
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // ==================================================
                        // REAL-TIME INTELLIGENCE
                        // ==================================================

                        const _RealtimeCard(),

                        const SizedBox(height: 16),

                        // ==================================================
                        // FLOW SUMMARY
                        // ==================================================

                        const _FlowSummaryCard(),
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

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar(BuildContext context) {
    return SizedBox(
      height: 38,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 38,
              minHeight: 38,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(
              Icons.arrow_back,
              size: 20,
              color: AppColors.darkCharcoal,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Settings',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 38,
              minHeight: 38,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Architecture settings will be available later.',
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.settings_outlined,
              size: 19,
              color: AppColors.darkCharcoal,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// LAYER TITLE
// ============================================================

class _LayerTitle extends StatelessWidget {
  final String text;

  const _LayerTitle({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: AppColors.darkCharcoal,
      ),
    );
  }
}

// ============================================================
// VERTICAL CONNECTOR
// ============================================================

class _VerticalConnector extends StatelessWidget {
  const _VerticalConnector();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 1.2,
            height: 10,
            color: AppColors.textSecondary.withOpacity(0.55),
          ),
          Icon(
            Icons.keyboard_arrow_down,
            size: 13,
            color: AppColors.textSecondary.withOpacity(0.75),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CORNER CARD
// Single reusable widget for all four "paired" boxes — Mobile
// App / Web App (Layer 1) and AI / ML Engine / Generative AI
// (Layer 4). Using one widget with one fixed width/height for
// every card guarantees both rows line up with identical sizes,
// and everything inside (icon, title, detail lines) is centered.
// ============================================================

class _CornerCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final List<String> lines;
  final double width;
  final double height;

  // width/height default to the Layer 4 (AI) card size, but any
  // call site can pass smaller values — e.g. the Layer 1 cards
  // below use a smaller size than the AI cards.
  const _CornerCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.lines,
    this.width = 165,
    this.height = 168,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: AppColors.tint(
            color,
            0.14,
          ),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: color.withOpacity(0.55),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 14,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.darkCharcoal,
              ),
            ),
            const SizedBox(height: 4),
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: Text(
                  line,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: AppColors.textSecondary,
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

// ============================================================
// BACKEND CARD
// ============================================================

class _BackendCard extends StatelessWidget {
  const _BackendCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: AppColors.tint(
          AppColors.statusGreen,
          0.15,
        ),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: AppColors.statusGreen.withOpacity(0.60),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.statusGreen.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.dns_outlined,
                  size: 16,
                  color: AppColors.statusGreen,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Backend API',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkCharcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          const Text(
            'ASP.NET Core',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Authentication',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Authorization',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Project Management',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Real-Time Updates',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DATA CARD
// ============================================================

class _DataCard extends StatelessWidget {
  const _DataCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 185,
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: AppColors.tint(
          AppColors.dataCyan,
          0.15,
        ),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: AppColors.dataCyan.withOpacity(0.60),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.dataCyan.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.storage_outlined,
                  size: 16,
                  color: AppColors.dataCyan,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Database',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkCharcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          const Text(
            'Projects',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Tasks',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Users',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Teams',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Deadlines',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Dependencies',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// REAL-TIME INTELLIGENCE
// ============================================================

class _RealtimeCard extends StatelessWidget {
  const _RealtimeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: AppColors.alertCoral.withOpacity(0.38),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: AppColors.alertCoral.withOpacity(0.13),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              size: 17,
              color: AppColors.alertCoral,
            ),
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Real-Time Intelligence',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkCharcoal,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Live project updates, AI insights, alerts, and '
                  'notifications across Web and Mobile.',
                  style: TextStyle(
                    fontSize: 9.5,
                    height: 1.25,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FLOW SUMMARY
// ============================================================

class _FlowSummaryCard extends StatelessWidget {
  const _FlowSummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: const Color(0xFFE3E6E8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Flow',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.darkCharcoal,
            ),
          ),
          const SizedBox(height: 8),
          const _FlowItem(
            number: '01',
            text: 'Users interact through Mobile and Web applications.',
            color: AppColors.usersPink,
          ),
          const _FlowItem(
            number: '02',
            text:
                'Backend API manages projects, tasks, users, and permissions.',
            color: AppColors.statusGreen,
          ),
          const _FlowItem(
            number: '03',
            text: 'Database stores project and operational data.',
            color: AppColors.dataCyan,
          ),
          const _FlowItem(
            number: '04',
            text: 'AI/ML analyzes project behavior and generates predictions.',
            color: AppColors.aiPurple,
          ),
          const _FlowItem(
            number: '05',
            text: 'Generative AI produces summaries and recommendations.',
            color: AppColors.priorityYellow,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FLOW ITEM
// ============================================================

class _FlowItem extends StatelessWidget {
  final String number;
  final String text;
  final Color color;

  const _FlowItem({
    required this.number,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 7,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.13),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 9.5,
                height: 1.25,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
