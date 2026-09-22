import 'package:flutter/material.dart';

import '../widgets/scaleflow_bottom_nav.dart';
import 'profile_screen.dart';
import 'projects_screen.dart';
import 'dashboard_screen.dart';
import 'home_screen.dart';

import 'risk_analysis_screen.dart';
import 'recommendations_screen.dart';
import 'trends_screen.dart';
import 'ai_report_screen.dart';

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({
    required this.text,
    required this.isUser,
  });
}

final List<String> suggestedPrompts = [
  "Project risks",
  "My workload",
  "Upcoming deadlines",
  "Project summary",
];

class AiInsightsPage extends StatefulWidget {
  const AiInsightsPage({super.key});

  @override
  State<AiInsightsPage> createState() => _AiInsightsPageState();
}

class _AiInsightsPageState extends State<AiInsightsPage> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final List<ChatMessage> _chatMessages = [];

  void _sendMessage() {
    final String message = _chatController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _chatMessages.add(ChatMessage(text: message, isUser: true));
      _chatController.clear();
      _chatMessages.add(
        ChatMessage(
          text: "AI response will be connected to the ScaleFlow backend soon.",
          isUser: false,
        ),
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_chatScrollController.hasClients) return;
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _useSuggestedPrompt(String prompt) {
    setState(() {
      _chatController.text = prompt;
    });
    _chatController.selection = TextSelection.fromPosition(
      TextPosition(offset: _chatController.text.length),
    );
  }

  @override
  void dispose() {
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FB),
      body: Stack(
        children: [
          // ====================================================
          // ====================================================
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C5CE7).withOpacity(0.08),
              ),
            ),
          ),

          // ====================================================
          // ====================================================
          Positioned(
            bottom: -120,
            left: -120,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C5CE7).withOpacity(0.06),
              ),
            ),
          ),

          // ====================================================
          // ====================================================
          Positioned.fill(
            child: Opacity(
              opacity: 0.10, 
              child: Image.asset(
                'assets/images/Proj-Image.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // ====================================================
          //          // ====================================================
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        const Text(
                          "Smarter insights. Better decisions.",
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF666A70),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildMainRiskBanner(context),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSmallGridCard(
                                icon: Icons.error_outline,
                                iconColor: const Color(0xFFE53935),
                                iconBg: const Color(0xFFFFEBEE),
                                title: "Risk Prediction",
                                subtitle: "3 projects at risk",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const RiskAnalysisScreen()),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildSmallGridCard(
                                icon: Icons.auto_awesome,
                                iconColor: const Color(0xFF6C5CE7),
                                iconBg: const Color(0xFFEFE9FE),
                                title: "Recommendations",
                                subtitle: "5 new suggestions",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const RecommendationsScreen()),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSmallGridCard(
                                icon: Icons.trending_up,
                                iconColor: const Color(0xFF2E7D32),
                                iconBg: const Color(0xFFE8F8EE),
                                title: "Trends",
                                subtitle: "Positive momentum",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const TrendsScreen()),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildSmallGridCard(
                                icon: Icons.description_outlined,
                                iconColor: const Color(0xFF3F82B8),
                                iconBg: const Color(0xFFE3F2FD),
                                title: "AI Report",
                                subtitle: "Generate report",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const AiReportScreen()),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Recent Insights",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF2C2D30),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildRecentInsightCard(context),
                        const SizedBox(height: 20),
                        _buildAskAiCard(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: ScaleFlowBottomNav(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          } else if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProjectsScreen()),
            );
          } else if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DashboardPage()),
            );
          } else if (index == 4) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          }
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Back',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back,
                size: 22, color: Color(0xFF2C2D30)),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              "AI Insights",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2D30),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFE9FE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 18,
              color: Color(0xFF6C5CE7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainRiskBanner(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RiskAnalysisScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white
              .withOpacity(0.92), 
          gradient: const LinearGradient(
            colors: [Color(0xFFFFEEF2), Color(0xFFF3E8FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEAD5E8), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFFFD6E0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_pin,
                color: Color(0xFFE53935),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Project Risk Alert",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      color: Color(0xFF2C2D30),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "The Midtown Tower project is at high risk of delay due to dependency issues and resource constraints.",
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF50545A),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: const [
                      Text(
                        "View Details",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6C5CE7),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward,
                          size: 14, color: Color(0xFF6C5CE7)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF6C5CE7), size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallGridCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
                color: Color(0xFF2C2D30),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF858990),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentInsightCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RecommendationsScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEFE9FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 18,
                color: Color(0xFF6C5CE7),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        "Resource Allocation",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF2C2D30),
                        ),
                      ),
                      Text(
                        "2h ago",
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF858990),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    "Consider reallocating 2 developers from Riverside Residence.",
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF666A70),
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

  Widget _buildAskAiCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 3),
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
                  color: const Color(0xFFEFE9FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: Color(0xFF6C5CE7),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Ask ScaleFlow AI",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C2D30),
                      ),
                    ),
                    Text(
                      "Get instant insights about your projects.",
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF858990),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_chatMessages.isNotEmpty) ...[
            SizedBox(
              height: 180,
              child: ListView.builder(
                controller: _chatScrollController,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _chatMessages.length,
                itemBuilder: (context, index) {
                  return _buildChatMessage(_chatMessages[index]);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F7FB),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome,
                    size: 14, color: Color(0xFF858990)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: "Ask anything...",
                      hintStyle:
                          TextStyle(fontSize: 12, color: Color(0xFF858990)),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.arrow_forward,
                      size: 16, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    minimumSize: const Size(32, 32),
                    maximumSize: const Size(32, 32),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: suggestedPrompts.map((prompt) {
              return GestureDetector(
                onTap: () => _useSuggestedPrompt(prompt),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F7FB),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Text(
                    prompt,
                    style:
                        const TextStyle(fontSize: 11, color: Color(0xFF2C2D30)),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessage(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: message.isUser
              ? const Color(0xFF6C5CE7)
              : const Color(0xFFF1F2F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontSize: 11.5,
            color: message.isUser ? Colors.white : const Color(0xFF2C2D30),
          ),
        ),
      ),
    );
  }
}
