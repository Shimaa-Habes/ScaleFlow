import 'package:flutter/material.dart';

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key});

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
                  const Text('AI Recommendations',
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
                  _buildRecCard(
                    title: 'Reallocate Developers',
                    description:
                        'Move 2 frontend engineers from Riverside Residence to Midtown Tower to fix timeline lags.',
                    impact: 'High Impact',
                    color: const Color(0xFF6C5CE7),
                  ),
                  _buildRecCard(
                    title: 'Optimize API Dependencies',
                    description:
                        'Run automated caching to speed up data fetch routines across microservices.',
                    impact: 'Medium Impact',
                    color: Colors.blue,
                  ),
                  _buildRecCard(
                    title: 'Schedule Stakeholder Sync',
                    description:
                        'Align design expectations with the client before the upcoming sprint review.',
                    impact: 'Low Impact',
                    color: Colors.green,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecCard(
      {required String title,
      required String description,
      required String impact,
      required Color color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(impact,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ),
              const Icon(Icons.auto_awesome,
                  size: 16, color: Color(0xFF6C5CE7)),
            ],
          ),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF2C2D30))),
          const SizedBox(height: 4),
          Text(description,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF666A70), height: 1.4)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  onPressed: () {},
                  child: const Text('Dismiss',
                      style: TextStyle(color: Colors.grey, fontSize: 12))),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                onPressed: () {},
                child: const Text('Apply Fix', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
