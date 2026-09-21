import 'package:flutter/material.dart';

class AiReportScreen extends StatelessWidget {
  const AiReportScreen({super.key});

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
                  const Text('Generated AI Report',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C2D30))),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Color(0x0A000000), blurRadius: 10)
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.description,
                                  color: Color(0xFF3F82B8), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('ScaleFlow Executive Summary',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFF2C2D30))),
                                SizedBox(height: 2),
                                Text('September 2026 • AI Generated',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF858990))),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        const Text('Executive Overview',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF6C5CE7))),
                        const SizedBox(height: 6),
                        const Text(
                            'The organization maintains an overall stable execution velocity. Critical attention is required for resource balancing in Midtown Tower to prevent project slippage.',
                            style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF666A70),
                                height: 1.4)),
                        const SizedBox(height: 16),
                        const Text('Key Highlights',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF6C5CE7))),
                        const SizedBox(height: 6),
                        const Text(
                            '• 4 Active Projects Monitored\n• 3 Bottlenecks Automatically Resolved\n• 88% Overall Task Completion Rate',
                            style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF666A70),
                                height: 1.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Report downloaded successfully!')));
                    },
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Download Full PDF Report',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
