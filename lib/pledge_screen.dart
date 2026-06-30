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

  // Helper function to execute the clipboard copy dynamically across different themes
  void _copyPaybillToClipboard(bool isDark) {
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
        // Softens up the banner background in dark layouts to prevent visual clashing
        backgroundColor: isDark ? const Color(0xFF1E88E5) : const Color(0xFF0D47A1),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🎨 DYNAMIC THEME DETECTOR INJECTIONS
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color mainTextColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white60 : Colors.black54;
    final Color cardBackground = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color inputFieldBg = isDark ? const Color(0xFF161616) : Colors.grey.shade50;
    final Color borderStrokeColor = isDark ? Colors.white24 : Colors.grey.shade300;
    final Color dividerLineColor = isDark ? Colors.white12 : Colors.grey;

    // 🎨 Adaptive Notice Card Theme Colors
    final Color noticeCardBg = isDark ? const Color(0xFF1A2638) : Colors.blue.shade50;
    final Color noticeCardBorder = isDark ? Colors.blue.shade900.withValues(alpha: 0.4) : Colors.blue.shade200;
    final Color noticeCardText = isDark ? Colors.blue.shade200 : Colors.blue.shade900;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pledges',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
        ),
        // 💡 Blends fluidly instead of drawing a hard amber line in Dark Mode
        backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.amberAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ℹ️ Informative Daraja Integration Notice Box (Adaptive Color Tuning)
              Card(
                elevation: 0,
                color: noticeCardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: noticeCardBorder, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: isDark ? Colors.blue.shade300 : Colors.blue.shade800, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            'System Integration Notice',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.blue.shade100 : Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This feature will be available when the app supports Daraja API, the collaboration with Safaricom and the Church accounts for pledge updates.',
                        style: TextStyle(
                          fontSize: 15,
                          color: noticeCardText,
                          height: 1.4,
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
                        activeColor: isDark ? Colors.blue[400] : const Color(0xFF0D47A1),
                        checkColor: isDark ? Colors.black : Colors.white,
                        value: _agreedToIncludeFunction,
                        onChanged: (bool? value) {
                          setState(() {
                            _agreedToIncludeFunction = value ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          'If you would like this function to be included please check below:\nI agree with that.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: mainTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Divider(color: dividerLineColor),
              ),

              // 💳 Manual M-Pesa Payment Portal Section
              Text(
                'To make Project Payment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: mainTextColor),
              ),
              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: inputFieldBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderStrokeColor),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('The Paybill is:', style: TextStyle(fontSize: 15, color: subTextColor)),
                        Text(
                          _paybillNumber,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: mainTextColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Account no is:', style: TextStyle(fontSize: 15, color: subTextColor)),
                        Container(
                          width: 140,
                          height: 4,
                          color: isDark ? Colors.white38 : Colors.black38, // Your clean custom underline field simulation
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 🙏 Continuing Thanks Footnote
              Text(
                'We hope you will continue using the app as we try to update it later. Thank you!',
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: subTextColor, height: 1.4),
              ),
              const SizedBox(height: 32),

              // 🖨️ Interactive Action Execution Hub
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => _copyPaybillToClipboard(isDark),
                  icon: const Icon(Icons.copy, size: 18, color: Colors.white),
                  label: const Text('Copy Paybill', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.blue[600] : const Color(0xFF0D47A1),
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