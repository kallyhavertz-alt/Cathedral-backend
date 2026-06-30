import 'package:flutter/material.dart';

class PhaseRoadmapScreen extends StatefulWidget {
  const PhaseRoadmapScreen({Key? key}) : super(key: key);

  @override
  State<PhaseRoadmapScreen> createState() => _PhaseRoadmapScreenState();
}

class _PhaseRoadmapScreenState extends State<PhaseRoadmapScreen> {
  @override
  Widget build(BuildContext context) {
    // 🎨 DYNAMIC THEME CONTROLLER DETECTORS
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color mainTextColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white70 : Colors.grey[800]!;
    final Color traceTextColor = isDark ? Colors.white60 : Colors.grey[600]!;
    final Color sectionHeaderColor = isDark ? Colors.grey[400]! : Colors.grey;

    final Color cardBackground = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color borderStrokeColor = isDark ? Colors.white24 : Colors.grey[300]!;
    final Color thumbnailBg = isDark ? const Color(0xFF262626) : Colors.grey[100]!;
    final Color footerQuoteBg = isDark ? const Color(0xFF161616) : Colors.grey[50]!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.redAccent),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Phase by Phase Roadmap',
          style: TextStyle(color: mainTextColor, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Images & Timeline Progression',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: sectionHeaderColor),
              ),
              const SizedBox(height: 16),

              // 🧱 PHASE 1: Foundation Group
              _buildPhaseSectionTitle('Foundation', isDark),
              _buildRoadmapItem(
                description: 'The basements, foundations and the trench containing it.',
                status: '100%',
                statusColor: Colors.green,
                textColor: mainTextColor,
                traceColor: traceTextColor,
                thumbBg: thumbnailBg,
                thumbBorder: borderStrokeColor,
              ),
              _buildRoadmapItem(
                description: 'The pillars during pilling & their completion status.',
                status: '100%',
                statusColor: Colors.green,
                textColor: mainTextColor,
                traceColor: traceTextColor,
                thumbBg: thumbnailBg,
                thumbBorder: borderStrokeColor,
              ),

              const SizedBox(height: 16),

              // 🧱 PHASE 2: Basement & Walls Group
              _buildPhaseSectionTitle('Basement & Walls', isDark),
              _buildRoadmapItem(
                description: 'The src walls - Painted white.',
                status: '98%',
                statusColor: isDark ? Colors.blue[400]! : const Color(0xFF0D47A1),
                textColor: mainTextColor,
                traceColor: traceTextColor,
                thumbBg: thumbnailBg,
                thumbBorder: borderStrokeColor,
              ),
              _buildRoadmapItem(
                description: 'The ground floor (basement roof) structural framing.',
                status: '95%',
                statusColor: isDark ? Colors.blue[400]! : const Color(0xFF0D47A1),
                textColor: mainTextColor,
                traceColor: traceTextColor,
                thumbBg: thumbnailBg,
                thumbBorder: borderStrokeColor,
              ),

              const SizedBox(height: 16),

              // 🧱 PHASE 3: Ground Floor Group
              _buildPhaseSectionTitle('Ground Floor', isDark),
              _buildRoadmapItem(
                description: 'Masonry work already done in progress.',
                status: '88%',
                statusColor: Colors.orange,
                textColor: mainTextColor,
                traceColor: traceTextColor,
                thumbBg: thumbnailBg,
                thumbBorder: borderStrokeColor,
              ),
              _buildRoadmapItem(
                description: 'Visible walls - External ground walls setting.',
                status: '87%',
                statusColor: Colors.orange,
                textColor: mainTextColor,
                traceColor: traceTextColor,
                thumbBg: thumbnailBg,
                thumbBorder: borderStrokeColor,
              ),

              const SizedBox(height: 32),

              // 📸 SECTION 4: The Full Photo Showcase Card (Themed Layout Frame)
              Text(
                'Project Overview',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: mainTextColor),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cardBackground,
                  border: Border.all(color: Colors.redAccent, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                      child: Image.asset(
                        'assets/icons/final.png',
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),

                    // Caption Area (Adaptive typography text parameters)
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'The Full Photo of the Church',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: mainTextColor),
                          ),
                          Text(
                            'Completion Status: 92%',
                            style: TextStyle(fontWeight: FontWeight.bold, color: subTextColor, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // 📜 SECTION 5: Motivational Bracketed Footer (Themed Card Layout)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: footerQuoteBg,
                  borderRadius: BorderRadius.circular(8),
                  border: const Border(
                    left: BorderSide(color: Colors.redAccent, width: 3),
                    right: BorderSide(color: Colors.redAccent, width: 3),
                  ),
                ),
                child: Text(
                  '" Cathedral is becoming real because of me and you. God bless us "',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: mainTextColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Section header helper with dynamic coloration configuration checks
  Widget _buildPhaseSectionTitle(String title, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.blue[300]! : const Color(0xFF0D47A1),
        ),
      ),
    );
  }

  // Row helper building individual item entries with themed contextual injections
  Widget _buildRoadmapItem({
    required String description,
    required String status,
    required Color statusColor,
    required Color textColor,
    required Color traceColor,
    required Color thumbBg,
    required Color thumbBorder,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: thumbBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: thumbBorder),
            ),
            child: Icon(Icons.image, size: 24, color: isDarkModeActive(thumbBg) ? Colors.white38 : Colors.grey[400]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: TextStyle(fontSize: 13.5, color: textColor, height: 1.3),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Completion Status: ',
                      style: TextStyle(fontSize: 12, color: traceColor),
                    ),
                    Text(
                      status,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Quick visibility flag check for thumbnail micro vectors
  bool isDarkModeActive(Color targetBg) => targetBg.toARGB32() == 0xFF262626;
}