import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ReportPostScreen extends StatefulWidget {
  final String postId;
  final String postAuthor;
  final int reportingMemberId;

  const ReportPostScreen({
    Key? key,
    required this.postId,
    required this.postAuthor,
    required this.reportingMemberId,
  }) : super(key: key);

  @override
  State<ReportPostScreen> createState() => _ReportPostScreenState();
}

class _ReportPostScreenState extends State<ReportPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  bool _isSending = false;

  String _selectedCategory = 'SPAM';
  final List<String> _categories = [
    'SPAM',
    'INAPPROPRIATE_CONTENT',
    'HARASSMENT',
    'MISINFORMATION',
    'OTHER'
  ];

  Future<void> _submitReportForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    final String targetUrl = 'http://192.168.100.33:8080/api/v1/community/posts/${widget.postId}/report';

    try {
      final response = await http.post(
        Uri.parse(targetUrl),
        headers: {
           "Content-Type": "application/json",
        },
        body: jsonEncode({
          "category": _selectedCategory,
          "reason": _reasonController.text.trim(),
          "reporterId": widget.reportingMemberId.toString(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you. The content has been flagged for administrative review.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        throw Exception();
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit report. Please check your connectivity and try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mainTextColor = isDark ? Colors.white : Colors.black87;
    final Color cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(Icons.close, color: mainTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Flag Content',
          style: TextStyle(color: mainTextColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Meta Header Context Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Reporting Content From:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(widget.postAuthor, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: mainTextColor)),
                    const SizedBox(height: 2),
                    Text('Post ID Reference: #${widget.postId}', style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'monospace')),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Category Selector Dropdown Field
              Text('Select a Category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: mainTextColor)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat.replaceAll('_', ' '), style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: 24),

              // Descriptive Details Form Text Box
              Text('Provide Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: mainTextColor)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                maxLines: 5,
                maxLength: 250,
                style: TextStyle(color: mainTextColor),
                decoration: InputDecoration(
                  hintText: 'Describe exactly why you find this content inappropriate or out-of-bounds for the community stream feed...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a valid justification reason statement for the audit team.';
                  }
                  if (value.trim().length < 10) {
                    return 'Please provide a slightly longer explanation context detail.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Dispatch Submission Trigger Action Row
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isSending ? null : _submitReportForm,
                  child: _isSending
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit Official Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}