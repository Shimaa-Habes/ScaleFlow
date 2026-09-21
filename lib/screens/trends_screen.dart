import 'package:flutter/material.dart';

class TrendsScreen extends StatelessWidget {
  const TrendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FB),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_back_ios_new,
                          size: 16, color: Color(0xFF2C2D30)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Performance Trends',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C2D30))),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF6C5CE7), Color(0xFF8B7CF4)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Positive Momentum',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12)),
                        SizedBox(height: 6),
                        Text('+24% Efficiency',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 6),
                        Text(
                            'Your team velocity increased compared to last month sprint.',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 11.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Weekly Velocity Metrics',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF2C2D30))),
                  const SizedBox(height: 12),
                  _buildTrendBar('Week 1', 0.60),
                  _buildTrendBar('Week 2', 0.75),
                  _buildTrendBar('Week 3', 0.85),
                  _buildTrendBar('Week 4 (Current)', 0.95),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendBar(String week, double value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(week,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF2C2D30))),
              Text('${(value * 100).toInt()}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF6C5CE7))),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: Colors.grey.shade100,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
            ),
          ),
        ],
      ),
    );
  }
}
