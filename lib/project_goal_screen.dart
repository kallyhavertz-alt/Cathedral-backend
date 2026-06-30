import 'package:flutter/material.dart';

class ProjectGoalScreen extends StatelessWidget {
  const ProjectGoalScreen({Key? key}) : super(key: key);

  // Core Financial Master Metrics
  final double amountRaised = 11368000;
  final double targetAmount = 20000000;

  @override
  Widget build(BuildContext context) {
    // 🎨 DYNAMIC THEME MODE PARAMETERS
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color mainTextColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white60 : Colors.black54;
    final Color cardBackground = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color progressRailBg = isDark ? Colors.white12 : Colors.grey.shade200;
    final Color borderStrokeColor = isDark ? Colors.white24 : Colors.grey.shade300;
    final Color rowDividerColor = isDark ? Colors.white10 : Colors.grey.shade100;

    double masterProgress = amountRaised / targetAmount;
    double remainingAmount = targetAmount - amountRaised;

    // 11 Months data dataset array configured to switch accent tones dynamically for dark canvases
    final List<Map<String, dynamic>> year2025Data = [
      {"month": "January", "budgeted": 119980, "raised": 120000, "color": isDark ? Colors.red.shade300 : Colors.red.shade700},
      {"month": "February", "budgeted": 450000, "raised": 430000, "color": isDark ? Colors.blue.shade300 : Colors.blue.shade700},
      {"month": "March", "budgeted": 380000, "raised": 400000, "color": isDark ? Colors.green.shade300 : Colors.green.shade700},
      {"month": "April", "budgeted": 290000, "raised": 280000, "color": isDark ? Colors.orange.shade300 : Colors.orange.shade700},
      {"month": "May", "budgeted": 500000, "raised": 490000, "color": isDark ? Colors.purple.shade300 : Colors.purple.shade700},
      {"month": "June", "budgeted": 310000, "raised": 320000, "color": isDark ? Colors.teal.shade300 : Colors.teal.shade700},
      {"month": "July", "budgeted": 420000, "raised": 410000, "color": isDark ? Colors.pink.shade300 : Colors.pink.shade700},
      {"month": "August", "budgeted": 350000, "raised": 360000, "color": isDark ? Colors.indigo.shade300 : Colors.indigo.shade700},
      {"month": "September", "budgeted": 400000, "raised": 390000, "color": isDark ? Colors.cyan.shade400 : Colors.cyan.shade800},
      {"month": "October", "budgeted": 380000, "raised": 370000, "color": isDark ? Colors.amber.shade400 : Colors.amber.shade900},
      {"month": "November", "budgeted": 390000, "raised": 380000, "color": isDark ? Colors.deepOrange.shade300 : Colors.deepOrange.shade700},
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: mainTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Project Goal',
          style: TextStyle(color: mainTextColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📊 SECTION 1: Financial Progression Master Panel
              Text(
                'Financial progression',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: subTextColor),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBackground,
                  border: Border.all(
                      color: isDark ? Colors.brown.shade400.withValues(alpha: 0.4) : Colors.brown.shade300,
                      width: 1.5
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Master Slider Indicator
                    Row(
                      children: [
                        Expanded(
                          flex: 8,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: masterProgress,
                              minHeight: 22,
                              backgroundColor: progressRailBg,
                              valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.blue[400]! : const Color(0xFF0D47A1)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '80% Progression',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: mainTextColor),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Value Metrics Stack
                    _buildFinancialRow('Amount Raised', 'KES ${amountRaised.toStringAsFixed(0)}', subTextColor, mainTextColor),
                    Divider(height: 20, color: rowDividerColor),
                    _buildFinancialRow('Target Amount', 'KES ${targetAmount.toStringAsFixed(0)}', subTextColor, mainTextColor),
                    Divider(height: 20, color: rowDividerColor),
                    _buildFinancialRow('Remaining', 'KES ${remainingAmount.toStringAsFixed(0)}', subTextColor, mainTextColor, isRed: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 📅 SECTION 2: Year 2025 Ledger Table Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tracker Month', style: TextStyle(fontWeight: FontWeight.bold, color: subTextColor)),
                  Text('Budgeted', style: TextStyle(fontWeight: FontWeight.bold, color: subTextColor)),
                  Text(
                      'Year 2025\nAmount Raised',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.blue[300] : Colors.blue.shade900)
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Dynamic Monthly Table Loop
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: year2025Data.length,
                itemBuilder: (context, index) {
                  final row = year2025Data[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: rowDividerColor)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            row['month'],
                            style: TextStyle(color: row['color'], fontWeight: FontWeight.bold, fontSize: 14)
                        ),
                        Text(
                            '${row['budgeted']}',
                            style: TextStyle(color: mainTextColor, fontFamily: 'monospace')
                        ),
                        Text(
                            '${row['raised']}',
                            style: TextStyle(color: mainTextColor, fontWeight: FontWeight.w500, fontFamily: 'monospace')
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Totals Rule row for 2025
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Totals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: mainTextColor)),
                    Text('4,000,000', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: mainTextColor)),
                    Text(
                        '3,950,000',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.blue[300] : Colors.blue.shade900)
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 📈 SECTION 3: Middle Projection Summary Box
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Progression Bar', style: TextStyle(fontSize: 13, color: subTextColor)),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: 0.80,
                            minHeight: 14,
                            backgroundColor: progressRailBg,
                            valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.white60 : Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Summary', style: TextStyle(fontSize: 12, color: traceTextColor(isDark), fontWeight: FontWeight.bold)),
                        Text(
                          'Possibility to meet this next year is achievable.',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.blue[300] : Colors.blue.shade900),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),

              // 🚀 SECTION 4: Year 2026 Future Ledger Placeholder
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBackground,
                  border: Border.all(color: borderStrokeColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tracker', style: TextStyle(fontWeight: FontWeight.bold, color: mainTextColor)),
                        Text('Budgeted', style: TextStyle(fontWeight: FontWeight.bold, color: subTextColor)),
                        Text(
                            'Year 2026\nAmount Raised',
                            textAlign: TextAlign.right,
                            style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.orange[300] : Colors.orange.shade900)
                        ),
                      ],
                    ),
                    Divider(color: rowDividerColor),
                    _buildFuturePlaceholderRow('January', isDark),
                    _buildFuturePlaceholderRow('February', isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper row builder for Master Data values (Themed parameters injected)
  Widget _buildFinancialRow(String title, String value, Color labelColor, Color valueColor, {bool isRed = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 14, color: labelColor, fontWeight: FontWeight.w500)),
        Text(
          value,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isRed ? Colors.redAccent : valueColor
          ),
        ),
      ],
    );
  }

  // Helper placeholder builder for future 2026 columns
  Widget _buildFuturePlaceholderRow(String month, bool isDark) {
    final Color placeholderColor = isDark ? Colors.white38 : Colors.grey;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(month, style: TextStyle(color: placeholderColor, fontWeight: FontWeight.w500)),
          Text('--', style: TextStyle(color: placeholderColor)),
          Text('--', style: TextStyle(color: placeholderColor)),
        ],
      ),
    );
  }

  // Helper to safely select tracer color boundaries
  Color traceTextColor(bool isDark) => isDark ? Colors.white38 : Colors.grey;
}