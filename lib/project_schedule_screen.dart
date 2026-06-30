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
    // 🎨 DYNAMIC THEME ENGINE INTEGRATIONS
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color mainTextColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white70 : Colors.grey[800]!;
    final Color traceTextColor = isDark ? Colors.white60 : Colors.grey[600]!;

    final Color summaryBoxBg = isDark ? const Color(0xFF161616) : Colors.grey[50]!;
    final Color cardBackground = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color borderStrokeColor = isDark ? Colors.white24 : Colors.grey[300]!;
    final Color inlineDividerColor = isDark ? Colors.white12 : Colors.grey[200]!;

    // 🎨 Adaptive tint for Zone 4 Probability Container
    final Color probabilityBg = isDark ? const Color(0xFF2C1A1A) : const Color(0xFFFFF5F5);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.redAccent),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Scope & Completion Schedule',
          style: TextStyle(color: mainTextColor, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📝 ZONE 1: Summary Box Description (Themed)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: summaryBoxBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderStrokeColor),
                ),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 14.5, color: mainTextColor, height: 1.5),
                    children: [
                      const TextSpan(text: "The "),
                      const TextSpan(text: "ACK grand project", style: TextStyle(fontWeight: FontWeight.bold)),
                      const TextSpan(text: " started on "),
                      TextSpan(
                        text: startDate,
                        style: TextStyle(
                            color: isDark ? Colors.blue[400] : const Color(0xFF0D47A1),
                            fontWeight: FontWeight.w600
                        ),
                      ),
                      const TextSpan(text: " and it is still ongoing. This project is scheduled to finish at "),
                      TextSpan(
                        text: estimatedEndDate,
                        style: TextStyle(
                            color: isDark ? Colors.blue[400] : const Color(0xFF0D47A1),
                            fontWeight: FontWeight.w600
                        ),
                      ),
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
                  style: TextStyle(fontSize: 13, color: traceTextColor, fontStyle: FontStyle.italic, height: 1.4),
                ),
              ),
              const SizedBox(height: 32),

              // 📊 ZONE 3: Calendar and Comparison Metrics Block (Themed)
              Text(
                'Calendar and Comparison.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: mainTextColor),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderStrokeColor),
                ),
                child: Column(
                  children: [
                    _buildMetricRow('Current Completion', '90%', Colors.green, mainTextColor),
                    Divider(height: 20, color: inlineDividerColor),
                    _buildMetricRow('Remaining', '10%', Colors.orange, mainTextColor),
                    Divider(height: 20, color: inlineDividerColor),
                    _buildMetricRow('End date', 'Dec 2026', isDark ? Colors.blue[300]! : const Color(0xFF0D47A1), mainTextColor),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 📉 ZONE 4: Timeline Probability Section (Themed & Tint-Protected)
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: probabilityBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Probability Lists Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProbabilityRow('Possibility to meet this', '70%', isDark ? Colors.green[400]! : Colors.green[700]!, subTextColor),
                          const SizedBox(height: 12),
                          _buildProbabilityRow('Not sure', '5%', isDark ? Colors.amber[400]! : Colors.amber[800]!, subTextColor),
                          const SizedBox(height: 12),
                          _buildProbabilityRow('Not to meet at all', '25%', Colors.redAccent, subTextColor),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 💡 Your right-hand accent indicator column remains vibrant
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

  // Helper widget builder for Zone 3 standard rows (Injected theme colors)
  Widget _buildMetricRow(String label, String value, Color valueColor, Color labelColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: labelColor),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: valueColor),
        ),
      ],
    );
  }

  // Helper widget builder for Zone 4 probability rows (Injected theme colors)
  Widget _buildProbabilityRow(String label, String percentage, Color color, Color labelColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: labelColor),
        ),
        Text(
          percentage,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}