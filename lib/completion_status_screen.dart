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
    {'name': 'Structural Pillars', 'percentage': 0.92, 'color': const Color(0xFF2196F3)}, // Brightened slightly for better visibility against dark cards
    {'name': 'Walls', 'percentage': 0.90, 'color': Colors.teal},
    {'name': 'Roofing', 'percentage': 0.85, 'color': const Color(0xFFE57373)}, // Softened dark red variant for adaptive contrast
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
    // 🎨 DYNAMIC SCREEN DETECTOR PARAMS
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color mainTextColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white70 : Colors.grey[700]!;
    final Color unselectedProgressBg = isDark ? Colors.white12 : Colors.grey[100]!;
    final Color cardBackground = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color borderStrokeColor = isDark ? Colors.white24 : Colors.grey[300]!;
    final Color nestedLogBg = isDark ? const Color(0xFF161616) : Colors.grey[50]!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.redAccent),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Completion Status',
          style: TextStyle(color: mainTextColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
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
                  color: subTextColor,
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
                    width: 150,
                    height: 150,
                    child: CustomPaint(
                      painter: GradientCircularPainter(
                        progress: completionPercentage,
                        isDarkModeActive: isDark, // Injected theme parameter flag
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(completionPercentage * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: mainTextColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Completed.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white60 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 📊 SECTION 3: Phases Completion Header Title
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Phases completion.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: mainTextColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Container Block framing your phase bar chart group (Themed)
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderStrokeColor, width: 1),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _constructionPhases.length,
                  itemBuilder: (context, index) {
                    final phase = _constructionPhases[index];
                    final double progressValue = phase['percentage'];

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              phase['name'],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: mainTextColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 5,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: SizedBox(
                                height: 12,
                                child: LinearProgressIndicator(
                                  value: progressValue,
                                  backgroundColor: unselectedProgressBg,
                                  valueColor: AlwaysStoppedAnimation<Color>(phase['color']),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
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
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Analysis & Progress Notes',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white60 : Colors.black54),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 140,
                width: double.infinity,
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: nestedLogBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderStrokeColor),
                ),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Text(
                    scrollableDetailText,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.grey[800],
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

// 🎨 GRADIENT CIRCULAR PAINTER UPDATED WITH DARK MODE AWARENESS
class GradientCircularPainter extends CustomPainter {
  final double progress;
  final bool isDarkModeActive; // New operational flag added to handle canvas rails safely

  GradientCircularPainter({required this.progress, required this.isDarkModeActive});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 12) / 2;

    final bgPaint = Paint()
      ..color = isDarkModeActive ? Colors.white10 : Colors.grey[100]! // Soft, non-blinding rail track indicator
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0;
    canvas.drawCircle(center, radius, bgPaint);

    final colors = [
      const Color(0xFF2196F3), // Brightened Blue anchor node
      const Color(0xFFD49A9A),
      const Color(0xFFC81919),
      const Color(0xFF5C0606),
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