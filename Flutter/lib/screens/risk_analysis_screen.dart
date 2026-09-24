import 'package:flutter/material.dart';

import '../services/risk_analysis_service.dart';

class RiskAnalysisScreen extends StatefulWidget {
  final int projectId;

  const RiskAnalysisScreen({
    super.key,
    required this.projectId,
  });

  @override
  State<RiskAnalysisScreen> createState() => _RiskAnalysisScreenState();
}

class _RiskAnalysisScreenState extends State<RiskAnalysisScreen> {
  final RiskAnalysisService _riskService = RiskAnalysisService();

  RiskAnalysisResult? _result;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRiskAnalysis();
  }

  Future<void> _loadRiskAnalysis() async {
    if (widget.projectId <= 0) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid project ID.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _riskService.analyzeRisk(
        projectId: widget.projectId,
        inputWindowDays: 30,
      );

      if (!mounted) return;

      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _cleanErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  String _cleanErrorMessage(Object error) {
    final message = error.toString();

    if (message.contains('SocketException')) {
      return 'Unable to connect to the ScaleFlow backend. '
          'Make sure the backend server is running.';
    }

    if (message.contains('401')) {
      return 'Your session has expired. Please log in again.';
    }

    if (message.contains('403')) {
      return 'You do not have permission to analyze this project.';
    }

    if (message.contains('404')) {
      return 'The selected project could not be found.';
    }

    if (message.contains('500')) {
      return 'The backend encountered an internal error while '
          'processing the AI analysis.';
    }

    return message.replaceFirst('Exception: ', '');
  }

  String _getRiskLevel(double score) {
    if (score >= 75) return 'Critical';
    if (score >= 50) return 'High';
    if (score >= 25) return 'Medium';
    return 'Low';
  }

  Color _getRiskColor(double score) {
    if (score >= 75) {
      return const Color(0xFFE53935);
    }

    if (score >= 50) {
      return const Color(0xFFE88973);
    }

    if (score >= 25) {
      return const Color(0xFFD8B84C);
    }

    return const Color(0xFF72B968);
  }

  Color _getRiskBackgroundColor(double score) {
    if (score >= 75) {
      return const Color(0xFFFFEBEE);
    }

    if (score >= 50) {
      return const Color(0xFFFFF1ED);
    }

    if (score >= 25) {
      return const Color(0xFFFFF8E5);
    }

    return const Color(0xFFEDF8EC);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE9EAED),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: Color(0xFF2C2D30),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Risk Analysis',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C2D30),
              ),
            ),
          ),
          GestureDetector(
            onTap: _isLoading ? null : _loadRiskAnalysis,
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE9EAED),
                ),
              ),
              child: Icon(
                Icons.refresh,
                size: 19,
                color: _isLoading
                    ? const Color(0xFFB5B7BC)
                    : const Color(0xFF6C5CE7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_result == null) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: const Color(0xFF6C5CE7),
      onRefresh: _loadRiskAnalysis,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _buildProjectContext(),
          const SizedBox(height: 14),
          _buildRiskSummary(),
          const SizedBox(height: 14),
          _buildModelConfidence(),
          const SizedBox(height: 14),
          _buildExplanation(),
          const SizedBox(height: 14),
          _buildCurrentStatus(),
          const SizedBox(height: 14),
          _buildAnalysisDetails(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFF0EDFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFF6C5CE7),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Analyzing project risk',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C2D30),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'ScaleFlow AI is analyzing the selected project.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF777B82),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Project #${widget.projectId}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6C5CE7),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          color: const Color(0xFFE7E8EC),
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

  Widget _buildRiskSummary() {
    final result = _result!;
    final score = result.riskScore.clamp(0, 100).toDouble();
    final riskLevel = _getRiskLevel(score);
    final riskColor = _getRiskColor(score);
    final riskBackground = _getRiskBackgroundColor(score);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE7E8EC),
        ),
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Project Risk',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666A70),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 142,
                height: 142,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 12,
                  backgroundColor: const Color(0xFFF0F1F3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    riskColor,
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    '${score.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: riskColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Risk Score',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF777B82),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: riskBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: riskColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  '$riskLevel Risk',
                  style: TextStyle(
                    color: riskColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelConfidence() {
    final confidence = (_result!.confidence * 100).clamp(0, 100).toDouble();

    return _buildInfoCard(
      title: 'Model Confidence',
      icon: Icons.psychology_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: confidence / 100,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF0F1F3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF6C5CE7),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${confidence.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C2D30),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Confidence indicates how strongly the trained model '
            'supports its current prediction.',
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: Color(0xFF858990),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanation() {
    return _buildInfoCard(
      title: 'AI Explanation',
      icon: Icons.auto_awesome_outlined,
      child: Text(
        _result!.explanation.isEmpty
            ? 'No additional explanation was returned by the AI model.'
            : _result!.explanation,
        style: const TextStyle(
          fontSize: 13,
          height: 1.5,
          color: Color(0xFF666A70),
        ),
      ),
    );
  }

  Widget _buildCurrentStatus() {
    final score = _result!.riskScore.clamp(0, 100).toDouble();
    final riskLevel = _getRiskLevel(score);
    final riskColor = _getRiskColor(score);
    final riskBackground = _getRiskBackgroundColor(score);

    return _buildInfoCard(
      title: 'Analysis Status',
      icon: Icons.analytics_outlined,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: riskBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: riskColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'The AI model currently classifies this project '
                'as $riskLevel risk.',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Color(0xFF555960),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisDetails() {
    return _buildInfoCard(
      title: 'Analysis Details',
      icon: Icons.info_outline,
      child: Column(
        children: [
          _buildDetailRow(
            label: 'Project ID',
            value: '#${_result!.projectId}',
          ),
          const SizedBox(height: 10),
          _buildDetailRow(
            label: 'Input window',
            value: '30 days',
          ),
          const SizedBox(height: 10),
          _buildDetailRow(
            label: 'Risk score',
            value:
                '${_result!.riskScore.clamp(0, 100).toStringAsFixed(2)} / 100',
          ),
          const SizedBox(height: 10),
          _buildDetailRow(
            label: 'Confidence',
            value:
                '${(_result!.confidence * 100).clamp(0, 100).toStringAsFixed(2)}%',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF777B82),
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C2D30),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE7E8EC),
        ),
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
                child: Icon(
                  icon,
                  size: 18,
                  color: const Color(0xFF6C5CE7),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C2D30),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EDFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.analytics_outlined,
                size: 34,
                color: Color(0xFF6C5CE7),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No risk analysis available',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C2D30),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The AI service did not return an analysis for this project.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFF777B82),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadRiskAnalysis,
              icon: const Icon(
                Icons.refresh,
                size: 18,
              ),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1ED),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 34,
                color: Color(0xFFE88973),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load risk analysis',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C2D30),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFF777B82),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Project #${widget.projectId}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6C5CE7),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadRiskAnalysis,
              icon: const Icon(
                Icons.refresh,
                size: 18,
              ),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
