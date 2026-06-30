import 'package:flutter/material.dart';

class AboutTrialBuildScreen extends StatelessWidget {
  const AboutTrialBuildScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mainTextColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white60 : Colors.grey.shade700;
    final Color cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50;
    final Color accentColor = isDark ? Colors.blue.shade300 : const Color(0xFF0D47A1);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: mainTextColor),
        title: Text('Trial Build Info', style: TextStyle(color: mainTextColor, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Build Version Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Current Status: Phase 1 Beta Build',
                style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'What This Phase Targets To Do:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: mainTextColor),
            ),
            const SizedBox(height: 12),

            // Core Objectives Checklist Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildObjectiveRow(Icons.dns_rounded, 'Local Dev Endpoint Handshake', 'Testing real-time network persistence loops against active internal Spring Boot/Java API servers.', isDark),
                  const Divider(height: 24),
                  _buildObjectiveRow(Icons.account_tree_rounded, 'Session Identity Anchoring', 'Verifying secure client-side storage states using shared preferences across reboots.', isDark),
                  const Divider(height: 24),
                  _buildObjectiveRow(Icons.palette_outlined, 'UI Fluid Adaptation Engine', 'Validating dark configuration overrides dynamically across interactive text inputs and drop-down menu layouts.', isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObjectiveRow(IconData icon, String title, String subtitle, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: isDark ? Colors.amberAccent : const Color(0xFF0D47A1), size: 24),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey.shade600, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }
}