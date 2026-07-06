import 'package:flutter/material.dart';
import 'package:untitled/project_goal.dart';
import 'package:untitled/project_goal_screen.dart';
import 'completion_status_update.dart';


class ProjectTrackScreen extends StatefulWidget {
  const ProjectTrackScreen({Key? key}) : super(key: key);

  @override
  State<ProjectTrackScreen> createState() => _ProjectTrackScreenState();
}

class _ProjectTrackScreenState extends State<ProjectTrackScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Tracking Manager', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.analytics_outlined), text: "Completion Status"),
            Tab(icon: Icon(Icons.flag_circle_outlined), text: "Project Goals"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const CompletionStatusUpdateScreen(),
          const ProjectGoalUpdateScreen(),
      ]
      ),
    );
  }
}