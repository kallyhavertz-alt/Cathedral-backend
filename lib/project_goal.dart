import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProjectGoalUpdateScreen extends StatefulWidget {
  const ProjectGoalUpdateScreen({Key? key}) : super(key: key);

  @override
  State<ProjectGoalUpdateScreen> createState() => _ProjectGoalUpdateScreenState();
}

class _ProjectGoalUpdateScreenState extends State<ProjectGoalUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form State Values
  String _selectedYear = '2026';
  String _selectedMonth = 'January';
  final _budgetedController = TextEditingController();
  final _raisedController = TextEditingController();
  final _summaryController = TextEditingController();

  final List<String> _years = ['2025', '2026', '2027', '2028'];
  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  Future<void> _sendUpdateToServer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Replace with your current backend environment URL
    final String targetUrl = 'http://192.168.100.33:8080/api/v1/project/goal/ledger-entry';

    try {
      final response = await http.post(
        Uri.parse(targetUrl),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "year": _selectedYear,
          "month": _selectedMonth,
          "budgeted": _budgetedController.text,
          "raised": _raisedController.text,
          "summary": _summaryController.text,
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Financial ledger metrics updated live!'), backgroundColor: Colors.green),
        );
        // Clear value fields upon successful database entry
        _budgetedController.clear();
        _raisedController.clear();
        _summaryController.clear();
      } else {
        throw Exception();
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🚨 Network transmission error, retry.'), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mainTextColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // 📑 APP BAR MATCHING IMAGE Layout
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: mainTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Project',
          style: TextStyle(color: mainTextColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 18.0),
            child: Text(
              'project goal',
              style: TextStyle(
                color: isDark ? Colors.blue[300] : Colors.blue[800],
                fontWeight: FontWeight.w600,
                fontSize: 16,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔽 YEAR DROPDOWN
              Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text('Year', style: TextStyle(fontSize: 16, color: mainTextColor, fontWeight: FontWeight.w500)),
                  ),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedYear,
                      isExpanded: true,
                      underline: Container(height: 1, color: Colors.grey),
                      items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                      onChanged: (val) => setState(() => _selectedYear = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 🔽 MONTH DROPDOWN
              Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text('Month', style: TextStyle(fontSize: 16, color: mainTextColor, fontWeight: FontWeight.w500)),
                  ),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedMonth,
                      isExpanded: true,
                      underline: Container(height: 1, color: Colors.grey),
                      items: _months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (val) => setState(() => _selectedMonth = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 📝 BUDGETED INPUT FIELD (Sketched Underline Style)
              TextFormField(
                controller: _budgetedController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: mainTextColor),
                decoration: InputDecoration(
                  labelText: 'Budgeted',
                  labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: const UnderlineInputBorder(),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              // 📝 RAISED INPUT FIELD (Sketched Underline Style)
              TextFormField(
                controller: _raisedController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: mainTextColor),
                decoration: InputDecoration(
                  labelText: 'Raised',
                  labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: const UnderlineInputBorder(),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 32),

              // 🔲 SUMMARY BOX AND INLINE ACTION BUTTON
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Summary /50',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: mainTextColor),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _summaryController,
                          maxLength: 50,
                          maxLines: 3,
                          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null, // Hidden native counter to preserve sketch layout cleanly
                          decoration: InputDecoration(
                            hintText: 'Enter general project timeline summary notes here...',
                            hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                            contentPadding: const EdgeInsets.all(10),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Inline Update Button from image 5283c4b9-f83b-4259-aa9e-dfc61b6e3037
                  Padding(
                    padding: const EdgeInsets.only(top: 26.0),
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _sendUpdateToServer,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isDark ? Colors.blue.shade300 : Colors.blue.shade800),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text('update', style: TextStyle(color: isDark ? Colors.blue[300] : Colors.blue[800], fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}