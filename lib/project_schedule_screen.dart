import 'package:flutter/material.dart';

class ProjectScheduleScreen extends StatefulWidget {
  const ProjectScheduleScreen({Key? key}) : super(key: key);

  @override
  State<ProjectScheduleScreen> createState() => _ProjectScheduleScreenState();
}

class _ProjectScheduleScreenState extends State<ProjectScheduleScreen> {
  // 💡 Hardcoded timeline variables matching your notebook draft lines
  final String startDate = "15th January 2024";
  final String estimatedEndDate = "20th December 2026";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.redAccent),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Scope & Completion Schedule',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📝 ZONE 1: Summary Box Description
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14.5, color: Colors.black87, height: 1.5),
                    children: [
                      const TextSpan(text: "The "),
                      const TextSpan(text: "ACK grand project", style: TextStyle(fontWeight: FontWeight.bold)),
                      const TextSpan(text: " started on "),
                      TextSpan(text: startDate, style: const TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.w600)),
                      const TextSpan(text: " and it is still ongoing. This project is scheduled to finish at "),
                      TextSpan(text: estimatedEndDate, style: const TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.w600)),
                      const TextSpan(text: "."),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 📢 ZONE 2: Italic Notice Prompt
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  'Continue coming back to this page for more information on schedule date changes and more.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600], fontStyle: FontStyle.italic, height: 1.4),
                ),
              ),
              const SizedBox(height: 32),

              // 📊 ZONE 3: Calendar and Comparison Metrics Block
              const Text(
                'Calendar and Comparison.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    _buildMetricRow('Current Completion', '90%', Colors.green),
                    const Divider(height: 20),
                    _buildMetricRow('Remaining', '10%', Colors.orange),
                    const Divider(height: 20),
                    _buildMetricRow('End date', 'Dec 2026', const Color(0xFF0D47A1)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 📉 ZONE 4: Timeline Probability Section
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5F5), // Light reddish tint background highlighting the metric assessment
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Probability Lists Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProbabilityRow('Possibility to meet this', '70%', Colors.green[700]!),
                          const SizedBox(height: 12),
                          _buildProbabilityRow('Not sure', '5%', Colors.amber[800]!),
                          const SizedBox(height: 12),
                          _buildProbabilityRow('Not to meet at all', '25%', Colors.redAccent),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 💡 Your right-hand accent indicator column
                    Container(
                      width: 4,
                      height: 85,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget builder for Zone 3 standard rows
  Widget _buildMetricRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: valueColor),
        ),
      ],
    );
  }

  // Helper widget builder for Zone 4 probability rows
  Widget _buildProbabilityRow(String label, String percentage, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[800]),
        ),
        Text(
          percentage,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}