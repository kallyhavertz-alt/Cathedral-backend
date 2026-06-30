import 'package:flutter/material.dart';
import 'package:untitled/completion_status_screen.dart';
import 'package:untitled/phase_roadmap_screen.dart';
import 'package:untitled/project_schedule_screen.dart';
import 'package:untitled/pledge_screen.dart';
import 'main.dart';
import 'package:untitled/project_goal_screen.dart';

class CathedralProjectScreen extends StatelessWidget {
  const CathedralProjectScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🎨 DYNAMIC THEME ENGINE COUPLING
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color mainTextColor = isDark ? Colors.white : Colors.black87;
    final Color cardBackground = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color bottomBorderColor = isDark ? Colors.white24 : Colors.grey[200]!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.redAccent),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }
          },
        ),
        title: Text(
          'The Cathedral Grand Project',
          style: TextStyle(color: mainTextColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🟥 TIER 1: Two Side-by-Side Upper Cards
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      context: context,
                      title: 'View Completion\nStatus',
                      icon: Icons.analytics,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CompletionStatusScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      context: context,
                      title: 'Scope and\nCompletion Schedule',
                      icon: Icons.calendar_month_outlined,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProjectScheduleScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 💊 TIER 2: Phase by Phase Roadmap Capsule Button
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PhaseRoadmapScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: cardBackground,
                    border: Border.all(color: Colors.redAccent, width: 1.5),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Phase by phase Roadmap',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: mainTextColor),
                      ),
                      const SizedBox(width: 8),
                      Transform.rotate(
                        angle: -0.5,
                        child: Icon(Icons.trending_flat, size: 18, color: mainTextColor),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // 📜 TIER 3: Goals and Pledges Navigation Rows
              Text(
                'Goals and Pledges.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: mainTextColor,
                ),
              ),
              const SizedBox(height: 12),

              _buildNavigationRow(
                label: 'Project goal',
                textColor: mainTextColor,
                borderColor: bottomBorderColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProjectGoalScreen()),
                  );
                },
              ),

              _buildNavigationRow(
                label: 'Pledge, give',
                textColor: mainTextColor,
                borderColor: bottomBorderColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PledgeScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper builder for Tier 1 Cards (Updated to pass context and render dynamically)
  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          border: Border.all(color: Colors.redAccent, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87
                ),
              ),
            ),
            Icon(icon, size: 28, color: isDark ? Colors.white70 : Colors.black87),
          ],
        ),
      ),
    );
  }

  // Helper builder for Tier 3 Row Options (Updated with dynamic theme parameter injectors)
  Widget _buildNavigationRow({
    required String label,
    required Color textColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: borderColor, width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor),
            ),
            const Icon(Icons.chevron_right, color: Colors.blue),
          ],
        ),
      ),
    );
  }
}