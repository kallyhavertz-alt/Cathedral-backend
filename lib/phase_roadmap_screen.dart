import 'package:flutter/material.dart';

class PhaseRoadmapScreen extends StatefulWidget {
  const PhaseRoadmapScreen({Key? key}) : super(key: key);

  @override
  State<PhaseRoadmapScreen> createState() => _PhaseRoadmapScreenState();
}

class _PhaseRoadmapScreenState extends State<PhaseRoadmapScreen> {
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
          'Phase by Phase Roadmap',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Images & Timeline Progression',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // 🧱 PHASE 1: Foundation Group
              _buildPhaseSectionTitle('Foundation'),
              _buildRoadmapItem(
                description: 'The basements, foundations and the trench containing it.',
                status: '100%',
                statusColor: Colors.green,
              ),
              _buildRoadmapItem(
                description: 'The pillars during pilling & their completion status.',
                status: '100%',
                statusColor: Colors.green,
              ),

              const SizedBox(height: 16),

              // 🧱 PHASE 2: Basement & Walls Group
              _buildPhaseSectionTitle('Basement & Walls'),
              _buildRoadmapItem(
                description: 'The src walls - Painted white.',
                status: '98%',
                statusColor: const Color(0xFF0D47A1),
              ),
              _buildRoadmapItem(
                description: 'The ground floor (basement roof) structural framing.',
                status: '95%',
                statusColor: const Color(0xFF0D47A1),
              ),

              const SizedBox(height: 16),

              // 🧱 PHASE 3: Ground Floor Group
              _buildPhaseSectionTitle('Ground Floor'),
              _buildRoadmapItem(
                description: 'Masonry work already done in progress.',
                status: '88%',
                statusColor: Colors.orange,
              ),
              _buildRoadmapItem(
                description: 'Visible walls - External ground walls setting.',
                status: '87%',
                statusColor: Colors.orange,
              ),

              const SizedBox(height: 32),

              // 📸 SECTION 4: The Full Photo Showcase Card (Updated to Offline Local Asset)
              const Text(
                'Project Overview',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.redAccent, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // 💡 Uses your local assets bundle directly—guaranteed to load instantly offline!
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                      child: Image.asset(
                        'assets/icons/final.png',
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),

                    // Caption Area
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'The Full Photo of the Church',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            'Completion Status: 92%',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // 📜 SECTION 5: Motivational Bracketed Footer
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: const Border(
                    left: BorderSide(color: Colors.redAccent, width: 3),
                    right: BorderSide(color: Colors.redAccent, width: 3),
                  ),
                ),
                child: const Text(
                  '" Cathedral is becoming real because of me and you. God bless us "',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
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

  // Section header helper for different phases
  Widget _buildPhaseSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
      ),
    );
  }

  // Row helper building individual item entries with left thumbnails
  Widget _buildRoadmapItem({
    required String description,
    required String status,
    required Color statusColor,
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
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Icon(Icons.image, size: 24, color: Colors.grey[400]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(fontSize: 13.5, color: Colors.black87, height: 1.3),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Completion Status: ',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
}