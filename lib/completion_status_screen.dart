import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CompletionStatusScreen extends StatefulWidget {
  const CompletionStatusScreen({Key? key}) : super(key: key);

  @override
  State<CompletionStatusScreen> createState() => _CompletionStatusScreenState();
}

class _ThemeColors {
  final Color mainText;
  final Color subText;
  final Color unselectedBg;
  final Color cardBg;
  final Color borderStroke;
  final Color nestedLogBg;

  _ThemeColors({
    required this.mainText,
    required this.subText,
    required this.unselectedBg,
    required this.cardBg,
    required this.borderStroke,
    required this.nestedLogBg,
  });
}

class _CompletionStatusScreenState extends State<CompletionStatusScreen> {
  bool _isLoading = true;
  bool _hasError = false;

  double _completionPercentage = 0.0;
  String _explanationText = "Loading project data...";
  String _scrollableDetailText = "";
  List<Map<String, dynamic>> _constructionPhases = [];

  @override
  void initState() {
    super.initState();
    _fetchProjectProgress();
  }

  // 🌐 FETCH WORKFLOW CONNECTING TO YOUR SPRING BOOT SERVICE
  Future<void> _fetchProjectProgress() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final String projectUrl = 'http://192.168.100.33:8080/api/v1/project/progress';

    try {
      final response = await http.get(Uri.parse(projectUrl)).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        setState(() {
          _completionPercentage = double.tryParse(data['completionPercentage'].toString()) ?? 0.0;
          _explanationText = data['explanationText'] ?? "No status overview provided.";
          _scrollableDetailText = data['analysisNotes'] ?? "No engineering tracking notes active.";

          final List<dynamic> rawPhases = data['constructionPhases'] ?? [];
          _constructionPhases = rawPhases.map((phase) {
            return {
              'name': phase['name'] ?? 'Unnamed Phase',
              'percentage': double.tryParse(phase['percentage'].toString()) ?? 0.0,
              // Convert hex string from backend to a native Flutter Color object
              'color': _parseHexColor(phase['color'] ?? '#2196F3'),
            };
          }).toList();

          _isLoading = false;
        });
      } else {
        throw Exception("Server error response code");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      debugPrint("🚨 Failed to sync with Grand Cathedral metrics: $e");
    }
  }

  Color _parseHexColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.blue; // Safe fallback structural color node
    }
  }

  _ThemeColors _getThemeColors(bool isDark) {
    return _ThemeColors(
      mainText: isDark ? Colors.white : Colors.black87,
      subText: isDark ? Colors.white70 : Colors.grey[700]!,
      unselectedBg: isDark ? Colors.white12 : Colors.grey[100]!,
      cardBg: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      borderStroke: isDark ? Colors.white24 : Colors.grey[300]!,
      nestedLogBg: isDark ? const Color(0xFF161616) : Colors.grey[50]!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors = _getThemeColors(isDark);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.redAccent),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Completion Status',
          style: TextStyle(color: themeColors.mainText, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: themeColors.mainText),
            onPressed: _fetchProjectProgress,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : _hasError
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                'Unable to load cathedral progress updates.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _fetchProjectProgress,
                child: const Text('Try Again', style: TextStyle(color: Colors.redAccent)),
              )
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchProjectProgress,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 📜 SECTION 1: Top Quote Explanation (Dynamic)
                Text(
                  '" $_explanationText "',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: themeColors.subText,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // 🎯 SECTION 2: Dynamic Centerpiece Wheel
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: CustomPaint(
                        painter: GradientCircularPainter(
                          progress: _completionPercentage,
                          isDarkModeActive: isDark,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(_completionPercentage * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: themeColors.mainText,
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

                // 📊 SECTION 3: Dynamic Phases Layout
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Phases completion.',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeColors.mainText,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: themeColors.cardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: themeColors.borderStroke, width: 1),
                  ),
                  child: _constructionPhases.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text('No structural sub-phases loaded yet.')),
                  )
                      : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _constructionPhases.length,
                    itemBuilder: (context, index) {
                      final phase = _constructionPhases[index];
                      final double progressValue = phase['percentage'];
                      final Color barColor = phase['color'];

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
                                  color: themeColors.mainText,
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
                                    backgroundColor: themeColors.unselectedBg,
                                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
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
                                    color: barColor,
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

                // 📝 SECTION 4: Dynamic Analysis & Remarks Box
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Analysis & Progress Notes',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white60 : Colors.black54),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 140,
                  width: double.infinity,
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: themeColors.nestedLogBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: themeColors.borderStroke),
                  ),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Text(
                      _scrollableDetailText,
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
      ),
    );
  }
}

class GradientCircularPainter extends CustomPainter {
  final double progress;
  final bool isDarkModeActive;

  GradientCircularPainter({required this.progress, required this.isDarkModeActive});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 12) / 2;

    final bgPaint = Paint()
      ..color = isDarkModeActive ? Colors.white10 : Colors.grey[100]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0;
    canvas.drawCircle(center, radius, bgPaint);

    final colors = [
      const Color(0xFF2196F3),
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