import 'package:flutter/material.dart';

class ProjectGoalScreen extends StatelessWidget {
  const ProjectGoalScreen({Key? key}) : super(key: key);

  // Core Financial Master Metrics (From your top sketch panel)
  final double amountRaised = 11368000;
  final double targetAmount = 20000000;

  @override
  Widget build(BuildContext context) {
    double masterProgress = amountRaised / targetAmount;
    double remainingAmount = targetAmount - amountRaised;

    // 11 Months data dataset array matching your exact layout specifications
    final List<Map<String, dynamic>> year2025Data = [
      {"month": "January", "budgeted": 119980, "raised": 120000, "color": Colors.red.shade700},
      {"month": "February", "budgeted": 450000, "raised": 430000, "color": Colors.blue.shade700},
      {"month": "March", "budgeted": 380000, "raised": 400000, "color": Colors.green.shade700},
      {"month": "April", "budgeted": 290000, "raised": 280000, "color": Colors.orange.shade700},
      {"month": "May", "budgeted": 500000, "raised": 490000, "color": Colors.purple.shade700},
      {"month": "June", "budgeted": 310000, "raised": 320000, "color": Colors.teal.shade700},
      {"month": "July", "budgeted": 420000, "raised": 410000, "color": Colors.pink.shade700},
      {"month": "August", "budgeted": 350000, "raised": 360000, "color": Colors.indigo.shade700},
      {"month": "September", "budgeted": 400000, "raised": 390000, "color": Colors.cyan.shade800},
      {"month": "October", "budgeted": 380000, "raised": 370000, "color": Colors.amber.shade900},
      {"month": "November", "budgeted": 390000, "raised": 380000, "color": Colors.deepOrange.shade700},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Project Goal',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
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
              const Text(
                'Financial progression',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black54),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.brown.shade300, width: 1.5),
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
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0D47A1)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          '80% Progression',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Value Metrics Stack
                    _buildFinancialRow('Amount Raised', 'KES ${amountRaised.toStringAsFixed(0)}'),
                    const Divider(height: 20),
                    _buildFinancialRow('Target Amount', 'KES ${targetAmount.toStringAsFixed(0)}'),
                    const Divider(height: 20),
                    _buildFinancialRow('Remaining', 'KES ${remainingAmount.toStringAsFixed(0)}', isRed: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 📅 SECTION 2: Year 2025 Ledger Table Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tracker Month', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                  const Text('Budgeted', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                  Text('Year 2025\nAmount Raised', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                ],
              ),
              const SizedBox(height: 8),

              // Dynamic 11 Colors Monthly Table Loop
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: year2025Data.length,
                itemBuilder: (context, index) {
                  final row = year2025Data[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
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
                            style: const TextStyle(color: Colors.black87, fontFamily: 'monospace')
                        ),
                        Text(
                            '${row['raised']}',
                            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontFamily: 'monospace')
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
                    const Text('Totals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Text('4,000,000', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    Text('3,950,000', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
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
                        const Text('Progression Bar', style: TextStyle(fontSize: 13, color: Colors.black54)),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: 0.80,
                            minHeight: 14,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.black87),
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
                        const Text('Summary', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                        Text(
                          'Possibility to meet this next year is achievable.',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.blue.shade900),
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
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tracker', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Text('Budgeted', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                        Text('Year 2026\nAmount Raised', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                      ],
                    ),
                    const Divider(),
                    _buildFuturePlaceholderRow('January'),
                    _buildFuturePlaceholderRow('February'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper row builder for Master Data values
  Widget _buildFinancialRow(String title, String value, {bool isRed = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500)),
        Text(
          value,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isRed ? Colors.redAccent : Colors.black87
          ),
        ),
      ],
    );
  }

  // Helper placeholder builder for future 2026 columns
  Widget _buildFuturePlaceholderRow(String month) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(month, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          const Text('--', style: TextStyle(color: Colors.grey)),
          const Text('--', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}