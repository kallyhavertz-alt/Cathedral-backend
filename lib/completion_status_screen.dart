import 'dart:math' as math;
import 'package:flutter/material.dart';

class CompletionStatusScreen extends StatefulWidget {
  const CompletionStatusScreen({Key? key}) : super(key: key);

  @override
  State<CompletionStatusScreen> createState() => _CompletionStatusScreenState();
}

class _CompletionStatusScreenState extends State<CompletionStatusScreen> {
  final double completionPercentage = 0.92; // Overall 92%

  final String explanationText =
      "The foundation, structural pillars, main sanctuary walls, and roofing layouts have been completely finalized.";

  // 💡 Hardcoded architectural data structure mapping your new phase sketch elements
  final List<Map<String, dynamic>> _constructionPhases = [
    {'name': 'Foundation', 'percentage': 1.00, 'color': Colors.green},
    {'name': 'Structural Pillars', 'percentage': 0.92, 'color': const Color(0xFF0A1931)}, // Matching our dark blue theme color
    {'name': 'Walls', 'percentage': 0.90, 'color': Colors.teal},
    {'name': 'Roofing', 'percentage': 0.85, 'color': const Color(0xFFC81919)}, // Deep accent red
    {'name': 'Floors', 'percentage': 0.47, 'color': Colors.orange},
    {'name': 'Basement', 'percentage': 0.45, 'color': Colors.blueGrey},
  ];

  final String scrollableDetailText =
      "Detailed Engineering Remarks:\n\n"
      "1. Phase 1 & 2 (Substructure & Framing) have passed full municipal structural safety audits.\n\n"
      "2. Wall masonry stands complete up to the lintel beams. Internal dividing partition setups are ongoing.\n\n"
      "3. Roofing sheets have been structurally anchored. Water-proofing treatment and ceiling board frameworks are slated for early next month.\n\n"
      "4. Floor screeding has commenced in the main vestry and administrative wings, with tile layout preparations following closely behind.";

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
          'Completion Status',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      // 💡 Wrapped in SingleChildScrollView so the entire screen handles smaller device viewports smoothly
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 📜 SECTION 1: Top Quote Explanation
              Text(
                '" $explanationText "',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // 🎯 SECTION 2: Premium Gradient Centerpiece Wheel
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 150, // Slightly scaled down to elegantly share vertical screen space
                    height: 150,
                    child: CustomPaint(
                      painter: GradientCircularPainter(
                        progress: completionPercentage,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(completionPercentage * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Completed.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 📊 SECTION 3: Phases Completion Header Title
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Phases completion.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Container Block framing your phase bar chart group
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(), // Scroll managed by parent container
                  itemCount: _constructionPhases.length,
                  itemBuilder: (context, index) {
                    final phase = _constructionPhases[index];
                    final double progressValue = phase['percentage'];

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Left side Label Text block
                          Expanded(
                            flex: 3,
                            child: Text(
                              phase['name'],
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Center Progress Bar tracking line
                          Expanded(
                            flex: 5,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: SizedBox(
                                height: 12,
                                child: LinearProgressIndicator(
                                  value: progressValue,
                                  backgroundColor: Colors.grey[100],
                                  valueColor: AlwaysStoppedAnimation<Color>(phase['color']),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Right side numerical percentage metric line
                          SizedBox(
                            width: 36,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${(progressValue * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: phase['color'],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),

              // 📝 SECTION 4: Scrollable Detailed Description Box
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Analysis & Progress Notes',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 140, // Fixed height box frame allows structural nested scrolling text area
                width: double.infinity,
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Text(
                    scrollableDetailText,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[800],
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🎨 KEEPING THE SWEEP GRADIENT CIRCULAR PAINTER INTACT BELOW
class GradientCircularPainter extends CustomPainter {
  final double progress;
  GradientCircularPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 12) / 2;

    final bgPaint = Paint()
      ..color = Colors.grey[100]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0;
    canvas.drawCircle(center, radius, bgPaint);

    final colors = [
      const Color(0xFF0A1931), // Dark Blue
      const Color(0xFFD49A9A), // Faded Red
      const Color(0xFFC81919), // Solid Red
      const Color(0xFF5C0606), // Dark Crimson
    ];

    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..shader = SweepGradient(
        colors: colors,
        startAngle: -math.pi / 2,
        endAngle: (math.pi * 2) - (math.pi / 2),
        tileMode: TileMode.clamp,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 12.0;

    final double sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}