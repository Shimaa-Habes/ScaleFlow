import 'package:flutter/material.dart';

import '../widgets/scaleflow_bottom_nav.dart';
import 'profile_screen.dart';
import 'projects_screen.dart';
import 'dashboard_screen.dart';
import 'home_screen.dart';
// ============================================================
// FAKE DATA MODELS
// ============================================================

class OverviewMetric {
  final String label;
  final String value;
  final String status;
  final Color bgColor;
  final Color statusColor;

  OverviewMetric(
    this.label,
    this.value,
    this.status,
    this.bgColor,
    this.statusColor,
  );
}

class RiskItem {
  final Color dotColor;
  final String task;
  final String project;
  final String riskLevel;
  final Color riskColor;

  RiskItem(
    this.dotColor,
    this.task,
    this.project,
    this.riskLevel,
    this.riskColor,
  );
}

// ============================================================
// CHAT MODEL
// ============================================================

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({
    required this.text,
    required this.isUser,
  });
}

// ============================================================
// FAKE DATA SOURCE
// ============================================================

final List<OverviewMetric> aiOverview = [
  OverviewMetric(
    "Project Health",
    "84%",
    "Healthy",
    const Color(0xFFDFF5E1),
    Colors.green,
  ),
  OverviewMetric(
    "Delay Risk",
    "18%",
    "Low",
    const Color(0xFFE4E9FE),
    Colors.indigo,
  ),
  OverviewMetric(
    "Workload Balance",
    "76%",
    "Good",
    const Color(0xFFDFF7F2),
    Colors.teal,
  ),
];

final String healthProjectName = "Website Redesign";
final double healthPercent = 0.84;
final String healthStatus = "Healthy";
final String healthDetails = "Progress: 72%, Risk: Low";
final String healthNote = "Project performance is currently on track.";

final String recommendationTag = "Potential Bottleneck";

final String recommendationTitle =
    "API Integration may delay Website Redesign.";

final String recommendationText =
    "Consider assigning one additional developer to reduce the current delay risk.";

final List<RiskItem> detectedRisks = [
  RiskItem(
    Colors.red,
    "API Integration",
    "Website Redesign",
    "High Risk",
    Colors.red,
  ),
  RiskItem(
    Colors.amber,
    "Client Testing",
    "Mobile App Launch",
    "Medium Risk",
    Colors.amber,
  ),
];

final List<String> suggestedPrompts = [
  "Project risks",
  "My workload",
  "Upcoming deadlines",
  "Project summary",
];

// ============================================================
// AI INSIGHTS PAGE
// ============================================================

class AiInsightsPage extends StatefulWidget {
  const AiInsightsPage({super.key});

  @override
  State<AiInsightsPage> createState() => _AiInsightsPageState();
}

class _AiInsightsPageState extends State<AiInsightsPage> {
  // ==========================================================
  // MAIN AI CHAT
  // ==========================================================

  final TextEditingController _chatController = TextEditingController();

  final ScrollController _chatScrollController = ScrollController();

  final List<ChatMessage> _chatMessages = [];

  // ==========================================================
  // SEND MAIN AI MESSAGE
  //
  // Temporary local behavior.
  // Later this method will call the Backend / AI API.
  // ==========================================================

  void _sendMessage() {
    final String message = _chatController.text.trim();

    if (message.isEmpty) {
      return;
    }

    setState(() {
      _chatMessages.add(
        ChatMessage(
          text: message,
          isUser: true,
        ),
      );

      _chatController.clear();

      // Temporary mock response.
      _chatMessages.add(
        ChatMessage(
          text: "AI response will be connected to the ScaleFlow backend soon.",
          isUser: false,
        ),
      );
    });

    // Automatically scroll to the latest message.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_chatScrollController.hasClients) {
        return;
      }

      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  // ==========================================================
  // SUGGESTED PROMPT
  // ==========================================================

  void _useSuggestedPrompt(String prompt) {
    setState(() {
      _chatController.text = prompt;
    });

    _chatController.selection = TextSelection.fromPosition(
      TextPosition(
        offset: _chatController.text.length,
      ),
    );
  }

  // ==========================================================
  // OPEN RECOMMENDATION CHAT
  // ==========================================================

  void _openRecommendationChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return const _RecommendationChatSheet();
      },
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _buildSectionTitle("AI Overview"),
                    const SizedBox(height: 10),
                    _buildOverviewRow(),
                    const SizedBox(height: 20),
                    _buildSectionTitle(
                      "Project Health + AI Recommendation",
                    ),
                    const SizedBox(height: 10),
                    _buildProjectHealthCard(),
                    const SizedBox(height: 12),
                    _buildRecommendationCard(),
                    const SizedBox(height: 20),
                    _buildSectionTitle("Detected Risks"),
                    const SizedBox(height: 10),
                    ...detectedRisks.map(_buildRiskTile),
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

      // ========================================================
      // SHARED SCALEFLOW BOTTOM NAVIGATION
      //
      // Home     = 0
      // Projects = 1
      // Dashboard = 2
      // AI       = 3
      // Profile  = 4
      // ========================================================

      bottomNavigationBar: ScaleFlowBottomNav(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacement(
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
          } else if (index == 4) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ProfileScreen(),
              ),
            );
          }
        },
      ),
    );
  }

  // ==========================================================
  // TOP APP BAR
  // ==========================================================

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: IconButton(
              tooltip: 'Back',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(
                Icons.arrow_back,
                size: 22,
                color: Color(0xFF2C2D30),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SizedBox(height: 3),
                Text(
                  "AI Insights",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2D30),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Smart intelligence across your projects",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
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

  // ==========================================================
  // SECTION TITLE
  // ==========================================================

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 15,
        color: Color(0xFF2C2D30),
      ),
    );
  }

  // ==========================================================
  // AI OVERVIEW
  // ==========================================================

  Widget _buildOverviewRow() {
    return Row(
      children: aiOverview.asMap().entries.map((entry) {
        final int index = entry.key;
        final OverviewMetric metric = entry.value;

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: index == aiOverview.length - 1 ? 0 : 8,
            ),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: metric.bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      metric.value,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        metric.status,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: metric.statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ==========================================================
  // PROJECT HEALTH CARD
  // ==========================================================

  Widget _buildProjectHealthCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  healthProjectName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      "${(healthPercent * 100).toInt()}%",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      healthStatus,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  healthDetails,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  healthNote,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: healthPercent,
                  strokeWidth: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.teal,
                  ),
                ),
                Text(
                  "${(healthPercent * 100).toInt()}%",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
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
  // AI RECOMMENDATION CARD
  // ==========================================================

  Widget _buildRecommendationCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _openRecommendationChat,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFE9FE),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF6C5CE7).withOpacity(0.18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: Color(0xFF6C5CE7),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      "AI Recommendation",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      recommendationTag,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF6C5CE7),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                recommendationTitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                recommendationText,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Text(
                    "View Recommendation",
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6C5CE7),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    size: 15,
                    color: Color(0xFF6C5CE7),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // DETECTED RISKS
  // ==========================================================

  Widget _buildRiskTile(RiskItem risk) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: risk.dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                ),
                children: [
                  TextSpan(
                    text: "${risk.task}, ",
                  ),
                  TextSpan(
                    text: "${risk.project}, ",
                  ),
                  TextSpan(
                    text: risk.riskLevel,
                    style: TextStyle(
                      color: risk.riskColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ASK SCALEFLOW AI
  // ==========================================================

  Widget _buildAskAiCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ----------------------------------------------------
          // HEADER
          // ----------------------------------------------------

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
                      ),
                    ),
                    Text(
                      "Get instant insights about your projects.",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ----------------------------------------------------
          // CHAT AREA
          // ONLY THIS AREA SCROLLS
          // ----------------------------------------------------

          if (_chatMessages.isNotEmpty) ...[
            SizedBox(
              height: 180,
              child: ListView.builder(
                controller: _chatScrollController,
                padding: const EdgeInsets.symmetric(
                  vertical: 4,
                ),
                itemCount: _chatMessages.length,
                itemBuilder: (context, index) {
                  return _buildChatMessage(
                    _chatMessages[index],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],

          // ----------------------------------------------------
          // INPUT
          // ----------------------------------------------------

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F7FB),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) {
                      _sendMessage();
                    },
                    decoration: const InputDecoration(
                      hintText: "Ask anything...",
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Colors.white,
                  ),
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

          // ----------------------------------------------------
          // SUGGESTED PROMPTS
          // ----------------------------------------------------

          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: suggestedPrompts.map(
              (prompt) {
                return GestureDetector(
                  onTap: () {
                    _useSuggestedPrompt(prompt);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F7FB),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.grey.shade200,
                      ),
                    ),
                    child: Text(
                      prompt,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ).toList(),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // MAIN CHAT MESSAGE
  // ==========================================================

  Widget _buildChatMessage(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 280,
        ),
        margin: const EdgeInsets.only(
          bottom: 6,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
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
            color: message.isUser ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// RECOMMENDATION CHAT SHEET
//
// Temporary local chat.
// Later it can connect directly to the Backend / AI service.
// ============================================================

class _RecommendationChatSheet extends StatefulWidget {
  const _RecommendationChatSheet();

  @override
  State<_RecommendationChatSheet> createState() =>
      _RecommendationChatSheetState();
}

class _RecommendationChatSheetState extends State<_RecommendationChatSheet> {
  final TextEditingController _controller = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [
    ChatMessage(
      isUser: false,
      text:
          "I detected a potential bottleneck in API Integration for Website Redesign.",
    ),
    ChatMessage(
      isUser: false,
      text: "Would you like advice on how to reduce the delay risk?",
    ),
  ];

  // ==========================================================
  // SEND RECOMMENDATION CHAT MESSAGE
  // ==========================================================

  void _sendMessage() {
    final String message = _controller.text.trim();

    if (message.isEmpty) {
      return;
    }

    setState(() {
      _messages.add(
        ChatMessage(
          text: message,
          isUser: true,
        ),
      );

      _controller.clear();

      // Temporary mock AI response.
      _messages.add(
        ChatMessage(
          isUser: false,
          text:
              "To reduce this bottleneck, consider reviewing the API dependency, redistributing the related tasks, and assigning additional development capacity if needed.",
        ),
      );
    });

    // Automatically scroll to the latest message.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.72,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      child: Column(
        children: [
          // ====================================================
          // SHEET HEADER
          // ====================================================

          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              14,
              12,
              10,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFE9FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Color(0xFF6C5CE7),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "AI Recommendation",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Get advice about this bottleneck",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: "Close",
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(
                    Icons.close,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ====================================================
          // RECOMMENDATION CHAT
          // ONLY THIS AREA SCROLLS
          // ====================================================

          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final ChatMessage message = _messages[index];

                return Align(
                  alignment: message.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 300,
                    ),
                    margin: const EdgeInsets.only(
                      bottom: 10,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? const Color(0xFF6C5CE7)
                          : const Color(0xFFF1F2F6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: message.isUser ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ====================================================
          // CHAT INPUT
          // ====================================================

          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                12,
                8,
                12,
                12,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7FB),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: Color(0xFF6C5CE7),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) {
                          _sendMessage();
                        },
                        decoration: const InputDecoration(
                          hintText: "Ask AI for advice...",
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: Colors.white,
                      ),
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
            ),
          ),
        ],
      ),
    );
  }
}
