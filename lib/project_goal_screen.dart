import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProjectGoalScreen extends StatefulWidget {
  const ProjectGoalScreen({Key? key}) : super(key: key);

  @override
  State<ProjectGoalScreen> createState() => _ProjectGoalScreenState();
}

class _ProjectGoalScreenState extends State<ProjectGoalScreen> {
  late Future<Map<String, dynamic>> _projectDataFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _projectDataFuture = _fetchProjectGoals();
    });
  }

  Future<Map<String, dynamic>> _fetchProjectGoals() async {
    final String url = 'http://192.168.100.33:8080/api/v1/project/goal/summary';
    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color mainTextColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white60 : Colors.black54;
    final Color cardBackground = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color progressRailBg = isDark ? Colors.white12 : Colors.grey.shade200;
    final Color borderStrokeColor = isDark ? Colors.white24 : Colors.grey.shade300;
    final Color rowDividerColor = isDark ? Colors.white10 : Colors.grey.shade100;

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
        actions: [
          IconButton(icon: Icon(Icons.refresh, color: mainTextColor), onPressed: _refreshData)
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _projectDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.money_off_csred_rounded, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('Could not load financial data progress.'),
                  TextButton(onPressed: _refreshData, child: const Text('Retry', style: TextStyle(color: Colors.blue)))
                ],
              ),
            );
          }

          final data = snapshot.data!;
          final double amountRaised = double.tryParse(data['amountRaised'].toString()) ?? 0.0;
          final double targetAmount = double.tryParse(data['targetAmount'].toString()) ?? 0.0;
          final double remainingAmount = double.tryParse(data['remainingAmount'].toString()) ?? 0.0;
          final double progressPercentage = double.tryParse(data['progressionPercentage'].toString()) ?? 0.0;
          final String projectionSummary = data['projectionSummary'] ?? 'No summary updated yet.';

          // Map holding yearly ledgers: e.g. {"2025": [...], "2026": [...]}
          final Map<String, dynamic> yearlyLedgers = data['yearlyLedgers'] ?? {};

          return RefreshIndicator(
            onRefresh: () async => _refreshData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 📊 SECTION 1: Master Financial Box
                    Text('Financial progression', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: subTextColor)),
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
                          Row(
                            children: [
                              Expanded(
                                flex: 8,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: progressPercentage,
                                    minHeight: 22,
                                    backgroundColor: progressRailBg,
                                    valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.blue[400]! : const Color(0xFF0D47A1)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${(progressPercentage * 100).toInt()}% Progress',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: mainTextColor),
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildFinancialRow('Amount Raised', 'KES ${amountRaised.toStringAsFixed(0)}', subTextColor, mainTextColor),
                          Divider(height: 20, color: rowDividerColor),
                          _buildFinancialRow('Target Amount', 'KES ${targetAmount.toStringAsFixed(0)}', subTextColor, mainTextColor),
                          Divider(height: 20, color: rowDividerColor),
                          _buildFinancialRow('Remaining', 'KES ${remainingAmount.toStringAsFixed(0)}', subTextColor, mainTextColor, isRed: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 📅 SECTION 2: DYNAMIC GENERATION OF YEARLY LEDGERS
                    if (yearlyLedgers.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No ledger tracks recorded yet.")))
                    else
                      ...yearlyLedgers.entries.map((entry) {
                        final String yearStr = entry.key;
                        final List<dynamic> monthsList = entry.value;

                         double totalBudgetedForYear = 0;
                        double totalRaisedForYear = 0;
                        for (var m in monthsList) {
                          totalBudgetedForYear += double.tryParse(m['budgeted'].toString()) ?? 0;
                          totalRaisedForYear += double.tryParse(m['raised'].toString()) ?? 0;
                        }

                        return Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                        child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                        color: cardBackground,
                        border: Border.all(color: borderStrokeColor),
                        borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                        Text('Tracker Month', style: TextStyle(fontWeight: FontWeight.bold, color: subTextColor)),
                        Text('Budgeted', style: TextStyle(fontWeight: FontWeight.bold, color: subTextColor)),
                        Text(
                        'Year $yearStr\nAmount Raised',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.blue[300] : Colors.blue.shade900)
                        ),
                        ],
                        ),
                        const Divider(height: 16),

                        // Dynamic Months rows
                        ...monthsList.map((monthData) {
                        return Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                        decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: rowDividerColor)),
                        ),
                        child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                        Text(
                        monthData['month'] ?? 'Unknown',
                        style: TextStyle(
                        color: isDark ? Colors.amber.shade300 : Colors.amber.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 14
                        )
                        ),
                        Text(
                        '${monthData['budgeted']}',
                        style: TextStyle(color: mainTextColor, fontFamily: 'monospace')
                        ),
                        Text(
                        '${monthData['raised']}',
                        style: TextStyle(color: mainTextColor, fontWeight: FontWeight.w500, fontFamily: 'monospace')
                        ),
                        ],
                        ),
                        );
                        }).toList(),

                        // Dynamic Year Totals Rule row
                        Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                        Text('Totals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: mainTextColor)),
                        Text(totalBudgetedForYear.toStringAsFixed(0), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: mainTextColor)),
                        Text(
                        totalRaisedForYear.toStringAsFixed(0),
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.blue[300] : Colors.blue.shade900)
                        ),
                        ],
                        ),
                        ),
                        ],
                        ),
                        ),
                        );
                      }).toList(),

                    // 📈 SECTION 3: Dynamic Projection Summary Box
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Progression Bar', style: TextStyle(fontSize: 13, color: subTextColor)),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progressPercentage,
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
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Summary', style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey, fontWeight: FontWeight.bold)),
                              Text(
                                projectionSummary,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.blue[300] : Colors.blue.shade900),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFinancialRow(String title, String value, Color labelColor, Color valueColor, {bool isRed = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 14, color: labelColor, fontWeight: FontWeight.w500)),
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isRed ? Colors.redAccent : valueColor),
        ),
      ],
    );
  }
}