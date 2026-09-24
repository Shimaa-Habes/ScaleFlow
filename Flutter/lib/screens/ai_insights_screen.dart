import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  'Project risks',
  'My workload',
  'Upcoming deadlines',
  'Project summary',
];

class AiInsightsPage extends StatefulWidget {
  final int projectId;

  const AiInsightsPage({
    super.key,
    required this.projectId,
  });

  @override
  State<AiInsightsPage> createState() => _AiInsightsPageState();
}

class _AiInsightsPageState extends State<AiInsightsPage> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  final List<ChatMessage> _chatMessages = [];

  bool _isSending = false;

  // ---------------------------------------------------------------
  // SEND CHAT MESSAGE
  // ---------------------------------------------------------------

  Future<void> _sendMessage() async {
    final String message = _chatController.text.trim();

    if (message.isEmpty || _isSending) return;

    setState(() {
      _chatMessages.add(
        ChatMessage(
          text: message,
          isUser: true,
        ),
      );

      _chatController.clear();
      _isSending = true;

      _chatMessages.add(
        ChatMessage(
          text: 'Thinking...',
          isUser: false,
        ),
      );
    });

    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5233/api/ai-chat'),
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'message': message,
        }),
      );

      if (!mounted) return;

      String reply;

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);

        reply = data['reply']?.toString() ??
            'I received your message, but no response was returned.';
      } else {
        try {
          final dynamic errorData = jsonDecode(response.body);

          reply = errorData['message']?.toString() ??
              'AI service returned an error.';
        } catch (_) {
          reply = 'AI service returned an error.';
        }
      }

      setState(() {
        if (_chatMessages.isNotEmpty &&
            _chatMessages.last.text == 'Thinking...') {
          _chatMessages.removeLast();
        }

        _chatMessages.add(
          ChatMessage(
            text: reply,
            isUser: false,
          ),
        );

        _isSending = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        if (_chatMessages.isNotEmpty &&
            _chatMessages.last.text == 'Thinking...') {
          _chatMessages.removeLast();
        }

        _chatMessages.add(
          ChatMessage(
            text:
                'Could not connect to ScaleFlow AI. Please make sure the backend is running.',
            isUser: false,
          ),
        );

        _isSending = false;
      });

      _scrollToBottom();
    }
  }

  // ---------------------------------------------------------------
  // SCROLL CHAT TO BOTTOM
  // ---------------------------------------------------------------

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_chatScrollController.hasClients) return;

      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  // ---------------------------------------------------------------
  // SUGGESTED PROMPT
  // ---------------------------------------------------------------

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

  // ---------------------------------------------------------------
  // OPEN RISK ANALYSIS
  // ---------------------------------------------------------------

  void _openRiskAnalysis() {
    if (widget.projectId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid project ID.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RiskAnalysisScreen(
          projectId: widget.projectId,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // OPEN RECOMMENDATIONS
  // ---------------------------------------------------------------

  void _openRecommendations() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RecommendationsScreen(),
      ),
    );
  }

  // ---------------------------------------------------------------
  // OPEN TRENDS
  // ---------------------------------------------------------------

  void _openTrends() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TrendsScreen(),
      ),
    );
  }

  // ---------------------------------------------------------------
  // OPEN AI REPORT
  // ---------------------------------------------------------------

  void _openAiReport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AiReportScreen(),
      ),
    );
  }

  // ---------------------------------------------------------------
  // DISPOSE
  // ---------------------------------------------------------------

  @override
  void dispose() {
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProjectContext(),

                    const SizedBox(height: 16),

                    const Text(
                      'Smarter insights. Better decisions.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF666A70),
                      ),
                    ),

                    const SizedBox(height: 14),

                    _buildMainRiskBanner(context),

                    const SizedBox(height: 16),

                    // ------------------------------------------------
                    // AI FEATURE CARDS
                    // ------------------------------------------------

                    Row(
                      children: [
                        Expanded(
                          child: _buildSmallGridCard(
                            icon: Icons.error_outline,
                            iconColor: const Color(0xFFE36B57),
                            iconBg: const Color(0xFFFFECE8),
                            title: 'Risk Prediction',
                            subtitle: 'Analyze project risk',
                            onTap: _openRiskAnalysis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildSmallGridCard(
                            icon: Icons.auto_awesome,
                            iconColor: const Color(0xFF6C5CE7),
                            iconBg: const Color(0xFFF0EDFF),
                            title: 'Recommendations',
                            subtitle: 'AI recommendations',
                            onTap: _openRecommendations,
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
                            iconColor: const Color(0xFF5B9B68),
                            iconBg: const Color(0xFFEAF7ED),
                            title: 'Trends',
                            subtitle: 'Project trends',
                            onTap: _openTrends,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildSmallGridCard(
                            icon: Icons.description_outlined,
                            iconColor: const Color(0xFF5B8FB8),
                            iconBg: const Color(0xFFEAF4FB),
                            title: 'AI Report',
                            subtitle: 'Generate report',
                            onTap: _openAiReport,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      'Recent Insights',
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

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // -------------------------------------------------------------
      // BOTTOM NAVIGATION
      // -------------------------------------------------------------

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
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const ProjectsScreen(),
              ),
            );
          } else if (index == 2) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const DashboardPage(),
              ),
            );
          } else if (index == 4) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const ProfileScreen(),
              ),
            );
          }
        },
      ),
    );
  }

  // ================================================================
  // TOP BAR
  // ================================================================

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Back',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back,
              size: 22,
              color: Color(0xFF2C2D30),
            ),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'AI Insights',
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
              color: const Color(0xFFF0EDFF),
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

  // ================================================================
  // PROJECT CONTEXT
  // ================================================================

  Widget _buildProjectContext() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EDFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.folder_open_outlined,
              size: 19,
              color: Color(0xFF6C5CE7),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Project',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF858990),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'AI analysis is scoped to this project',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C2D30),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F7FB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '#${widget.projectId}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6C5CE7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // MAIN RISK BANNER
  // ================================================================

  Widget _buildMainRiskBanner(BuildContext context) {
    return GestureDetector(
      onTap: _openRiskAnalysis,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE6E1F7),
            width: 1,
          ),
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
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFFFFECE8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.analytics_outlined,
                color: Color(0xFFE36B57),
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Project Risk Analysis',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      color: Color(0xFF2C2D30),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'View the latest AI-powered risk analysis for this project.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF50545A),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Text(
                        'View Analysis',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6C5CE7),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: Color(0xFF6C5CE7),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF6C5CE7),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // SMALL GRID CARD
  // ================================================================

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
        constraints: const BoxConstraints(
          minHeight: 126,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE7E8EC),
          ),
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
              child: Icon(
                icon,
                size: 18,
                color: iconColor,
              ),
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

  // ================================================================
  // RECENT INSIGHT
  // ================================================================

  Widget _buildRecentInsightCard(BuildContext context) {
    return GestureDetector(
      onTap: _openRecommendations,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE7E8EC),
          ),
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
                color: const Color(0xFFF0EDFF),
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
                      Expanded(
                        child: Text(
                          'Resource Allocation',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF2C2D30),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'AI Insight',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF858990),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'View AI-generated recommendations for project resources.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF666A70),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Text(
                        'View recommendations',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6C5CE7),
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(
                        Icons.arrow_forward,
                        size: 12,
                        color: Color(0xFF6C5CE7),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // ASK AI
  // ================================================================

  Widget _buildAskAiCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE7E8EC),
        ),
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
                  color: const Color(0xFFF0EDFF),
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
                      'Ask ScaleFlow AI',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C2D30),
                      ),
                    ),
                    Text(
                      'Ask about this project.',
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

          // ----------------------------------------------------------
          // CHAT MESSAGES
          // ----------------------------------------------------------

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

          // ----------------------------------------------------------
          // CHAT INPUT
          // ----------------------------------------------------------

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F7FB),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: Color(0xFF858990),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    enabled: !_isSending,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Ask anything...',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF858990),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isSending ? null : _sendMessage,
                  icon: _isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
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

          // ----------------------------------------------------------
          // SUGGESTED PROMPTS
          // ----------------------------------------------------------

          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: suggestedPrompts.map((prompt) {
              return GestureDetector(
                onTap: _isSending ? null : () => _useSuggestedPrompt(prompt),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F7FB),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Text(
                    prompt,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF2C2D30),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // CHAT MESSAGE
  // ================================================================

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
            color: message.isUser ? Colors.white : const Color(0xFF2C2D30),
          ),
        ),
      ),
    );
  }
}
