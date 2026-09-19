// import 'package:flutter/material.dart';

// import '../core/app_colors.dart';
// import '../widgets/scaleflow_bottom_nav.dart';
// import 'ai_insights_screen.dart';
// import 'dashboard_screen.dart';
// import 'profile_screen.dart';
// import 'projects_screen.dart';

// class ArchitecturePage extends StatelessWidget {
//   const ArchitecturePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Directionality(
//       textDirection: TextDirection.ltr,
//       child: Scaffold(
//         backgroundColor: AppColors.background,

//         // ============================================================
//         // BOTTOM NAVIGATION
//         // ============================================================

//         bottomNavigationBar: ScaleFlowBottomNav(
//           currentIndex: 1,
//           onTap: (index) {
//             if (index == 0) {
//               Navigator.of(context).pop();
//             } else if (index == 1) {
//               Navigator.of(context).push(
//                 MaterialPageRoute(
//                   builder: (_) => const ProjectsScreen(),
//                 ),
//               );
//             } else if (index == 2) {
//               Navigator.of(context).push(
//                 MaterialPageRoute(
//                   builder: (_) => const DashboardPage(),
//                 ),
//               );
//             } else if (index == 3) {
//               Navigator.of(context).push(
//                 MaterialPageRoute(
//                   builder: (_) => const AiInsightsPage(),
//                 ),
//               );
//             } else if (index == 4) {
//               Navigator.of(context).push(
//                 MaterialPageRoute(
//                   builder: (_) => const ProfileScreen(),
//                 ),
//               );
//             }
//           },
//         ),

//         // ============================================================
//         // BODY
//         // ============================================================

//         body: SafeArea(
//           child: LayoutBuilder(
//             builder: (context, constraints) {
//               final maxWidth =
//                   constraints.maxWidth < 600 ? constraints.maxWidth : 460.0;

//               return Center(
//                 child: SingleChildScrollView(
//                   padding: const EdgeInsets.fromLTRB(
//                     20,
//                     8,
//                     20,
//                     24,
//                   ),
//                   child: ConstrainedBox(
//                     constraints: BoxConstraints(
//                       maxWidth: maxWidth,
//                     ),
//                     child: Column(
//                       children: [
//                         _buildTopBar(context),

//                         const SizedBox(height: 4),

//                         const Text(
//                           'Architecture',
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             fontSize: 22,
//                             fontWeight: FontWeight.w700,
//                             color: AppColors.darkCharcoal,
//                           ),
//                         ),

//                         const SizedBox(height: 4),

//                         const Text(
//                           'How ScaleFlow connects projects, data, AI, and users.',
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             fontSize: 11,
//                             color: AppColors.textSecondary,
//                           ),
//                         ),

//                         const SizedBox(height: 13),

//                         // ==================================================
//                         // LAYER 1 — USER APPLICATIONS
//                         // Same size as the Layer 4 cards below, and text is
//                         // centered both horizontally and vertically.
//                         // ==================================================

//                         const _LayerTitle(
//                           text: 'Layer 1 — User Applications',
//                         ),

//                         const SizedBox(height: 7),

//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: const [
//                             _CornerCard(
//                               color: AppColors.usersPink,
//                               icon: Icons.phone_android_outlined,
//                               title: 'Mobile App',
//                               lines: ['Flutter'],
//                               width: 130,
//                               height: 100,
//                             ),
//                             SizedBox(width: 8),
//                             _CornerCard(
//                               color: AppColors.dataCyan,
//                               icon: Icons.web_outlined,
//                               title: 'Web App',
//                               lines: ['Next.js'],
//                               width: 130,
//                               height: 100,
//                             ),
//                           ],
//                         ),

//                         const _VerticalConnector(),

//                         // ==================================================
//                         // LAYER 2 — BACKEND API
//                         // ==================================================

//                         const _LayerTitle(
//                           text: 'Layer 2 — Backend API',
//                         ),

//                         const SizedBox(height: 7),

//                         const _BackendCard(),

//                         const _VerticalConnector(),

//                         // ==================================================
//                         // LAYER 3 — DATA
//                         // ==================================================

//                         const _LayerTitle(
//                           text: 'Layer 3 — Data',
//                         ),

//                         const SizedBox(height: 7),

//                         const _DataCard(),

//                         const _VerticalConnector(),

//                         // ==================================================
//                         // LAYER 4 — AI & INTELLIGENCE
//                         // Same _CornerCard used above, so both rows share
//                         // identical width/height and centered text.
//                         // ==================================================

//                         const _LayerTitle(
//                           text: 'Layer 4 — AI & Intelligence',
//                         ),

//                         const SizedBox(height: 7),

//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: const [
//                             _CornerCard(
//                               color: AppColors.aiPurple,
//                               icon: Icons.auto_awesome,
//                               title: 'AI / ML Engine',
//                               lines: [
//                                 'Delay Prediction',
//                                 'Risk Scoring',
//                                 'Bottleneck Detection',
//                                 'Workload Analysis',
//                               ],
//                             ),
//                             SizedBox(width: 8),
//                             _CornerCard(
//                               color: AppColors.priorityYellow,
//                               icon: Icons.psychology_outlined,
//                               title: 'Generative AI',
//                               lines: [
//                                 'Executive Summaries',
//                                 'Recommendations',
//                                 'Project Reports',
//                               ],
//                             ),
//                           ],
//                         ),

//                         const SizedBox(height: 10),

//                         // ==================================================
//                         // REAL-TIME INTELLIGENCE
//                         // ==================================================

//                         const _RealtimeCard(),

//                         const SizedBox(height: 16),

//                         // ==================================================
//                         // FLOW SUMMARY
//                         // ==================================================

//                         const _FlowSummaryCard(),
//                       ],
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // TOP BAR
//   // ============================================================

//   Widget _buildTopBar(BuildContext context) {
//     return SizedBox(
//       height: 38,
//       child: Row(
//         children: [
//           IconButton(
//             tooltip: 'Back',
//             padding: EdgeInsets.zero,
//             constraints: const BoxConstraints(
//               minWidth: 38,
//               minHeight: 38,
//             ),
//             onPressed: () {
//               Navigator.of(context).pop();
//             },
//             icon: const Icon(
//               Icons.arrow_back,
//               size: 20,
//               color: AppColors.darkCharcoal,
//             ),
//           ),
//           const Spacer(),
//           IconButton(
//             tooltip: 'Settings',
//             padding: EdgeInsets.zero,
//             constraints: const BoxConstraints(
//               minWidth: 38,
//               minHeight: 38,
//             ),
//             onPressed: () {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text(
//                     'Architecture settings will be available later.',
//                   ),
//                 ),
//               );
//             },
//             icon: const Icon(
//               Icons.settings_outlined,
//               size: 19,
//               color: AppColors.darkCharcoal,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ============================================================
// // LAYER TITLE
// // ============================================================

// class _LayerTitle extends StatelessWidget {
//   final String text;

//   const _LayerTitle({
//     required this.text,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Text(
//       text,
//       textAlign: TextAlign.center,
//       style: const TextStyle(
//         fontSize: 11.5,
//         fontWeight: FontWeight.w600,
//         color: AppColors.darkCharcoal,
//       ),
//     );
//   }
// }

// // ============================================================
// // VERTICAL CONNECTOR
// // ============================================================

// class _VerticalConnector extends StatelessWidget {
//   const _VerticalConnector();

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 24,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 1.2,
//             height: 10,
//             color: AppColors.textSecondary.withOpacity(0.55),
//           ),
//           Icon(
//             Icons.keyboard_arrow_down,
//             size: 13,
//             color: AppColors.textSecondary.withOpacity(0.75),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ============================================================
// // CORNER CARD
// // Single reusable widget for all four "paired" boxes — Mobile
// // App / Web App (Layer 1) and AI / ML Engine / Generative AI
// // (Layer 4). Using one widget with one fixed width/height for
// // every card guarantees both rows line up with identical sizes,
// // and everything inside (icon, title, detail lines) is centered.
// // ============================================================

// class _CornerCard extends StatelessWidget {
//   final Color color;
//   final IconData icon;
//   final String title;
//   final List<String> lines;
//   final double width;
//   final double height;

//   // width/height default to the Layer 4 (AI) card size, but any
//   // call site can pass smaller values — e.g. the Layer 1 cards
//   // below use a smaller size than the AI cards.
//   const _CornerCard({
//     required this.color,
//     required this.icon,
//     required this.title,
//     required this.lines,
//     this.width = 165,
//     this.height = 168,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: width,
//       height: height,
//       child: Container(
//         padding: const EdgeInsets.symmetric(
//           horizontal: 10,
//           vertical: 8,
//         ),
//         decoration: BoxDecoration(
//           color: AppColors.tint(
//             color,
//             0.14,
//           ),
//           borderRadius: BorderRadius.circular(11),
//           border: Border.all(
//             color: color.withOpacity(0.55),
//             width: 1,
//           ),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Container(
//               width: 26,
//               height: 26,
//               decoration: BoxDecoration(
//                 color: color.withOpacity(0.18),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 icon,
//                 size: 14,
//                 color: color,
//               ),
//             ),
//             const SizedBox(height: 6),
//             Text(
//               title,
//               textAlign: TextAlign.center,
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//               style: const TextStyle(
//                 fontSize: 11,
//                 fontWeight: FontWeight.w700,
//                 color: AppColors.darkCharcoal,
//               ),
//             ),
//             const SizedBox(height: 4),
//             ...lines.map(
//               (line) => Padding(
//                 padding: const EdgeInsets.only(bottom: 1),
//                 child: Text(
//                   line,
//                   textAlign: TextAlign.center,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     fontSize: 9.5,
//                     color: AppColors.textSecondary,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ============================================================
// // BACKEND CARD
// // ============================================================

// class _BackendCard extends StatelessWidget {
//   const _BackendCard();

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 190,
//       padding: const EdgeInsets.symmetric(
//         horizontal: 13,
//         vertical: 11,
//       ),
//       decoration: BoxDecoration(
//         color: AppColors.tint(
//           AppColors.statusGreen,
//           0.15,
//         ),
//         borderRadius: BorderRadius.circular(11),
//         border: Border.all(
//           color: AppColors.statusGreen.withOpacity(0.60),
//           width: 1,
//         ),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: 28,
//                 height: 28,
//                 decoration: BoxDecoration(
//                   color: AppColors.statusGreen.withOpacity(0.18),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.dns_outlined,
//                   size: 16,
//                   color: AppColors.statusGreen,
//                 ),
//               ),
//               const SizedBox(width: 8),
//               const Text(
//                 'Backend API',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.w700,
//                   color: AppColors.darkCharcoal,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 7),
//           const Text(
//             'ASP.NET Core',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 10.5,
//               color: AppColors.textSecondary,
//             ),
//           ),
//           const SizedBox(height: 2),
//           const Text(
//             'Authentication',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 10.5,
//               color: AppColors.textSecondary,
//             ),
//           ),
//           const SizedBox(height: 2),
//           const Text(
//             'Authorization',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 10.5,
//               color: AppColors.textSecondary,
//             ),
//           ),
//           const SizedBox(height: 2),
//           const Text(
//             'Project Management',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 10.5,
//               color: AppColors.textSecondary,
//             ),
//           ),
//           const SizedBox(height: 2),
//           const Text(
//             'Real-Time Updates',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 10.5,
//               color: AppColors.textSecondary,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ============================================================
// // DATA CARD
// // ============================================================

// class _DataCard extends StatelessWidget {
//   const _DataCard();

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 185,
//       padding: const EdgeInsets.symmetric(
//         horizontal: 13,
//         vertical: 11,
//       ),
//       decoration: BoxDecoration(
//         color: AppColors.tint(
//           AppColors.dataCyan,
//           0.15,
//         ),
//         borderRadius: BorderRadius.circular(11),
//         border: Border.all(
//           color: AppColors.dataCyan.withOpacity(0.60),
//           width: 1,
//         ),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: 28,
//                 height: 28,
//                 decoration: BoxDecoration(
//                   color: AppColors.dataCyan.withOpacity(0.18),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.storage_outlined,
//                   size: 16,
//                   color: AppColors.dataCyan,
//                 ),
//               ),
//               const SizedBox(width: 8),
//               const Text(
//                 'Database',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.w700,
//                   color: AppColors.darkCharcoal,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 7),
//           const Text(
//             'Projects',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 10.5,
//               color: AppColors.textSecondary,
//             ),
//           ),
//           const SizedBox(height: 2),
//           const Text(
//             'Tasks',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 10.5,
//               color: AppColors.textSecondary,
//             ),
//           ),
//           const SizedBox(height: 2),
//           const Text(
//             'Users',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 10.5,
//               color: AppColors.textSecondary,
//             ),
//           ),
//           const SizedBox(height: 2),
//           const Text(
//             'Teams',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 10.5,
//               color: AppColors.textSecondary,
//             ),
//           ),
//           const SizedBox(height: 2),
//           const Text(
//             'Deadlines',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 10.5,
//               color: AppColors.textSecondary,
//             ),
//           ),
//           const SizedBox(height: 2),
//           const Text(
//             'Dependencies',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 10.5,
//               color: AppColors.textSecondary,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ============================================================
// // REAL-TIME INTELLIGENCE
// // ============================================================

// class _RealtimeCard extends StatelessWidget {
//   const _RealtimeCard();

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(
//         horizontal: 12,
//         vertical: 10,
//       ),
//       decoration: BoxDecoration(
//         color: AppColors.surfaceWhite,
//         borderRadius: BorderRadius.circular(11),
//         border: Border.all(
//           color: AppColors.alertCoral.withOpacity(0.38),
//         ),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 31,
//             height: 31,
//             decoration: BoxDecoration(
//               color: AppColors.alertCoral.withOpacity(0.13),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(
//               Icons.notifications_active_outlined,
//               size: 17,
//               color: AppColors.alertCoral,
//             ),
//           ),
//           const SizedBox(width: 9),
//           const Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Real-Time Intelligence',
//                   style: TextStyle(
//                     fontSize: 11,
//                     fontWeight: FontWeight.w700,
//                     color: AppColors.darkCharcoal,
//                   ),
//                 ),
//                 SizedBox(height: 3),
//                 Text(
//                   'Live project updates, AI insights, alerts, and '
//                   'notifications across Web and Mobile.',
//                   style: TextStyle(
//                     fontSize: 9.5,
//                     height: 1.25,
//                     color: AppColors.textSecondary,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ============================================================
// // FLOW SUMMARY
// // ============================================================

// class _FlowSummaryCard extends StatelessWidget {
//   const _FlowSummaryCard();

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: AppColors.surfaceWhite,
//         borderRadius: BorderRadius.circular(11),
//         border: Border.all(
//           color: const Color(0xFFE3E6E8),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'System Flow',
//             style: TextStyle(
//               fontSize: 11.5,
//               fontWeight: FontWeight.w700,
//               color: AppColors.darkCharcoal,
//             ),
//           ),
//           const SizedBox(height: 8),
//           const _FlowItem(
//             number: '01',
//             text: 'Users interact through Mobile and Web applications.',
//             color: AppColors.usersPink,
//           ),
//           const _FlowItem(
//             number: '02',
//             text:
//                 'Backend API manages projects, tasks, users, and permissions.',
//             color: AppColors.statusGreen,
//           ),
//           const _FlowItem(
//             number: '03',
//             text: 'Database stores project and operational data.',
//             color: AppColors.dataCyan,
//           ),
//           const _FlowItem(
//             number: '04',
//             text: 'AI/ML analyzes project behavior and generates predictions.',
//             color: AppColors.aiPurple,
//           ),
//           const _FlowItem(
//             number: '05',
//             text: 'Generative AI produces summaries and recommendations.',
//             color: AppColors.priorityYellow,
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ============================================================
// // FLOW ITEM
// // ============================================================

// class _FlowItem extends StatelessWidget {
//   final String number;
//   final String text;
//   final Color color;

//   const _FlowItem({
//     required this.number,
//     required this.text,
//     required this.color,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(
//         bottom: 7,
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 24,
//             height: 24,
//             alignment: Alignment.center,
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.13),
//               shape: BoxShape.circle,
//             ),
//             child: Text(
//               number,
//               style: TextStyle(
//                 fontSize: 8,
//                 fontWeight: FontWeight.w700,
//                 color: color,
//               ),
//             ),
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(
//                 fontSize: 9.5,
//                 height: 1.25,
//                 color: AppColors.textSecondary,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../widgets/scaleflow_bottom_nav.dart';
import 'ai_insights_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'projects_screen.dart';

// ============================================================
// ARCHITECTURE PAGE — PROFESSIONAL VARIANT
// Same content/data as the original design (layers, cards,
// real-time intelligence, flow summary, navigation) but with a
// cleaner "SaaS docs" visual language: white cards with a
// colored left accent bar, icon in a rounded square, detail
// items shown as small pill chips, and a timeline connector
// running down the left side between layers.
// ============================================================

class ArchitecturePage extends StatelessWidget {
  const ArchitecturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.background,

        // ============================================================
        // BOTTOM NAVIGATION (unchanged)
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
                  constraints.maxWidth < 600 ? constraints.maxWidth : 480.0;

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(context),
                        const SizedBox(height: 10),

                        // ==================================================
                        // TITLE
                        // ==================================================

                        _buildTitleSection(),
                        const SizedBox(height: 22),

                        // ==================================================
                        // LAYER 1 — USER APPLICATIONS
                        // ==================================================

                        _TimelineStep(
                          index: '01',
                          title: 'User Applications',
                          isFirst: true,
                          child: Row(
                            children: const [
                              Expanded(
                                child: _ProCard(
                                  color: AppColors.usersPink,
                                  icon: Icons.phone_android_outlined,
                                  title: 'Mobile App',
                                  chips: ['Flutter'],
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: _ProCard(
                                  color: AppColors.dataCyan,
                                  icon: Icons.web_outlined,
                                  title: 'Web App',
                                  chips: ['Next.js'],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ==================================================
                        // LAYER 2 — BACKEND API
                        // ==================================================

                        _TimelineStep(
                          index: '02',
                          title: 'Backend API',
                          child: const _ProCard(
                            color: AppColors.statusGreen,
                            icon: Icons.dns_outlined,
                            title: 'Backend API',
                            chips: [
                              'ASP.NET Core',
                              'Authentication',
                              'Authorization',
                              'Project Management',
                              'Real-Time Updates',
                            ],
                          ),
                        ),

                        // ==================================================
                        // LAYER 3 — DATA
                        // ==================================================

                        _TimelineStep(
                          index: '03',
                          title: 'Data',
                          child: const _ProCard(
                            color: AppColors.dataCyan,
                            icon: Icons.storage_outlined,
                            title: 'Database',
                            chips: [
                              'Projects',
                              'Tasks',
                              'Users',
                              'Teams',
                              'Deadlines',
                              'Dependencies',
                            ],
                          ),
                        ),

                        // ==================================================
                        // LAYER 4 — AI & INTELLIGENCE
                        // ==================================================

                        _TimelineStep(
                          index: '04',
                          title: 'AI & Intelligence',
                          isLast: true,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Expanded(
                                child: _ProCard(
                                  color: AppColors.aiPurple,
                                  icon: Icons.auto_awesome,
                                  title: 'AI / ML Engine',
                                  chips: [
                                    'Delay Prediction',
                                    'Risk Scoring',
                                    'Bottleneck Detection',
                                    'Workload Analysis',
                                  ],
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: _ProCard(
                                  color: AppColors.priorityYellow,
                                  icon: Icons.psychology_outlined,
                                  title: 'Generative AI',
                                  chips: [
                                    'Executive Summaries',
                                    'Recommendations',
                                    'Project Reports',
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ==================================================
                        // REAL-TIME INTELLIGENCE
                        // ==================================================

                        const _RealtimeBanner(),

                        const SizedBox(height: 14),

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
            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
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
            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
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

  // ============================================================
  // TITLE SECTION
  // A small icon badge above the heading, left-aligned like a
  // typical product/docs page rather than a centered app screen.
  // ============================================================

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.aiPurple.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.account_tree_outlined,
            size: 22,
            color: AppColors.aiPurple,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Architecture',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.darkCharcoal,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'How ScaleFlow connects projects, data, AI, and users.',
          style: TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// TIMELINE STEP
// Wraps a layer's content with a numbered node on the left, a
// vertical connecting line running through it, and the layer's
// label + content on the right. This replaces the small
// centered arrows from the previous design with a clearer,
// more "documentation style" flow.
// ============================================================

class _TimelineStep extends StatelessWidget {
  final String index;
  final String title;
  final Widget child;
  final bool isFirst;
  final bool isLast;

  const _TimelineStep({
    required this.index,
    required this.title,
    required this.child,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ========================================================
          // NODE + CONNECTING LINE
          // ========================================================
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.darkCharcoal,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  index,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.4,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppColors.textSecondary.withOpacity(0.25),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // ========================================================
          // LABEL + CONTENT
          // ========================================================
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  child,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PRO CARD
// White card, colored accent bar on the left, icon in a rounded
// square, bold title, and details rendered as small pill chips
// instead of plain bullet lines — the main visual difference
// from the previous design.
// ============================================================

class _ProCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final List<String> chips;

  const _ProCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.chips,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8EC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Accent bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(icon, size: 16, color: color),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkCharcoal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: chips.map((chip) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            chip,
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
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
// REAL-TIME INTELLIGENCE BANNER
// Full-width highlighted banner, styled to match the new card
// language (accent bar + rounded icon square).
// ============================================================

class _RealtimeBanner extends StatelessWidget {
  const _RealtimeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.alertCoral.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.alertCoral.withOpacity(0.25)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.alertCoral.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              size: 18,
              color: AppColors.alertCoral,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Real-Time Intelligence',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkCharcoal,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Live project updates, AI insights, alerts, and '
                  'notifications across Web and Mobile.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
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
// FLOW SUMMARY CARD
// Same five steps as before, restyled with numbered square
// badges instead of circles to match the new card language.
// ============================================================

class _FlowSummaryCard extends StatelessWidget {
  const _FlowSummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Flow',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.darkCharcoal,
            ),
          ),
          const SizedBox(height: 10),
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
            isLast: true,
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
  final bool isLast;

  const _FlowItem({
    required this.number,
    required this.text,
    required this.color,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
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
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                height: 1.35,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
