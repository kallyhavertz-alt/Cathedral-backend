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
    return Scaffold(
      backgroundColor: Colors.white,
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
        title: const Text(
          'The Cathedral Grand Project',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
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
                      title: 'View Completion\nStatus',
                      icon: Icons.analytics, // Matches your bar chart sketch
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
                      title: 'Scope and\nCompletion Schedule',
                      icon: Icons.calendar_month_outlined, // Matches your document/schedule sketch
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
                    border: Border.all(color: Colors.redAccent, width: 1.5),
                    borderRadius: BorderRadius.circular(30), // Rounded capsule style
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Phase by phase Roadmap',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(width: 8),
                      Transform.rotate(
                        angle: -0.5, // Tilts the arrow upwards slightly to match your sketch
                        child: const Icon(Icons.trending_flat, size: 18, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // 📜 TIER 3: Goals and Pledges Navigation Rows
              const Text(
                'Goals and Pledges.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              _buildNavigationRow(
                label: 'Project goal',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const
                    ProjectGoalScreen()),
                  );
                  // TODO: Wire up navigation
                },
              ),

              _buildNavigationRow(
                label: 'Pledge, give',
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

  // Helper builder for Tier 1 Cards
  Widget _buildActionCard({required String title, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
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
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            Icon(icon, size: 28, color: Colors.black87),
          ],
        ),
      ),
    );
  }

  // Helper builder for Tier 3 Row Options
  Widget _buildNavigationRow({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
            ),
            const Icon(Icons.chevron_right, color: Colors.blue),
          ],
        ),
      ),
    );
  }
}