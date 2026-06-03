import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for Clipboard operations

class PledgeScreen extends StatefulWidget {
  const PledgeScreen({super.key});

  @override
  State<PledgeScreen> createState() => _CathedralProjectScreenState();
}

class _CathedralProjectScreenState extends State<PledgeScreen> {
  bool _agreedToIncludeFunction = false;
  final String _paybillNumber = "593225";

  // Helper function to execute the native clipboard copy on the Realme C71
  void _copyPaybillToClipboard() {
    Clipboard.setData(ClipboardData(text: _paybillNumber));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Text('Paybill $_paybillNumber copied to clipboard!'),
          ],
        ),
        backgroundColor: const Color(0xFF0D47A1), // Cathedral Blue
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
            // Clears back to main navigation safely
          },
        ),
        title: const Text('Pledges'),
        backgroundColor: Colors.amberAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ℹ️ Informative Daraja Integration Notice Box
              Card(
                elevation: 0,
                color: Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.blue.shade200, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade800, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            'System Integration Notice',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This feature will be available when the app supports Daraja API, the collaboration with Safaricom and the Church accounts for pledge updates.',
                        style: TextStyle(
                            fontSize: 15,
                            color: Colors.blue.shade900,
                            height: 1.4
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 🗳️ User Preference Handshake Lane
              InkWell(
                onTap: () {
                  setState(() {
                    _agreedToIncludeFunction = !_agreedToIncludeFunction;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  child: Row(
                    children: [
                      Checkbox(
                        activeColor: const Color(0xFF0D47A1),
                        value: _agreedToIncludeFunction,
                        onChanged: (bool? value) {
                          setState(() {
                            _agreedToIncludeFunction = value ?? false;
                          });
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'If you would like this function to be included please check below:\nI agree with that.',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Divider(color: Colors.grey),
              ),

              // 💳 Manual M-Pesa Payment Portal Section
              const Text(
                'To make Project Payment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('The Paybill is:', style: TextStyle(fontSize: 15, color: Colors.black54)),
                        Text(
                            _paybillNumber,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Account no is:', style: TextStyle(fontSize: 15, color: Colors.black54)),
                        Container(
                          width: 140,
                          height: 4,
                          color: Colors.black38, // Simulates your exact handwritten line field cleanly
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 🙏 Continuing Thanks Footnote
              const Text(
                'We hope you will continue using the app as we try to update it later. Thank you!',
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black54, height: 1.4),
              ),
              const SizedBox(height: 32),

              // 🖨️ Interactive Action Execution Hub
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _copyPaybillToClipboard,
                  icon: const Icon(Icons.copy, size: 18, color: Colors.white),
                  label: const Text('Copy Paybill', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1), // Cathedral Corporate Blue
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
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