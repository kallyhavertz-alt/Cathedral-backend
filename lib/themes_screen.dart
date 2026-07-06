import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:untitled/session_manager.dart';

class ThemesScreen extends StatefulWidget {
  final Color primaryColor;

  const ThemesScreen({
    Key? key,
    required this.primaryColor,
  }) : super(key: key);

  @override
  State<ThemesScreen> createState() => _ThemesScreenState();
}

class _ThemesScreenState extends State<ThemesScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _readingController = TextEditingController();
  final TextEditingController _themeController = TextEditingController();

  String _selectedThemeType = 'WEEKLY';
  bool _isLoading = false;

  final String _baseUrl = 'http://192.168.100.33:8080/api/v1';

  @override
  void dispose() {
    _readingController.dispose();
    _themeController.dispose();
    super.dispose();
  }

  Future<void> _submitThemeForm() async {
    if (!_formKey.currentState!.validate()) return;

    final String? activeStaff = SessionManager.currentStaffId;
    if (activeStaff == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No active staff session found.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final String publishUrl = '$_baseUrl/staff/themes/publish';

    try {
      final response = await http.post(
        Uri.parse(publishUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'themeText': _themeController.text.trim(),
          'themeType': _selectedThemeType,
          'reading': _readingController.text.trim(),
          'senderId': activeStaff,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Theme broadcasted successfully to all profiles!'),
            backgroundColor: Colors.green,
          ),
        );

         _readingController.clear();
        _themeController.clear();
      } else {
        throw Exception("Server status code: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish theme: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mainTextColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white60 : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Theme.of(context).cardColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: mainTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Themes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: mainTextColor),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            Text(
              'Themes written here will be visible to everyone',
              style: TextStyle(fontSize: 14, color: subTextColor, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),

             DropdownButtonFormField<String>(
              value: _selectedThemeType,
              dropdownColor: Theme.of(context).cardColor,
              style: TextStyle(color: mainTextColor, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.primaryColor, width: 2)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              items: const [
                DropdownMenuItem(value: 'WEEKLY', child: Text('Theme of the week')),
                DropdownMenuItem(value: 'MONTHLY', child: Text('Theme of Month')),
                DropdownMenuItem(value: 'YEARLY', child: Text('Theme of the year')),
              ],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedThemeType = newValue;
                  });
                }
              },
            ),
            const SizedBox(height: 24),

             TextFormField(
              controller: _readingController,
              style: TextStyle(color: mainTextColor),
              maxLines: 4,
              minLines: 2,
              decoration: InputDecoration(
                labelText: 'Reading',
                labelStyle: TextStyle(color: widget.primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.primaryColor, width: 2)),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter the reading script structure' : null,
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _themeController,
              style: TextStyle(color: mainTextColor),
              maxLines: 5,
              minLines: 3,
              decoration: InputDecoration(
                labelText: 'Theme',
                labelStyle: TextStyle(color: widget.primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.primaryColor, width: 2)),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter the theme description text' : null,
            ),
            const SizedBox(height: 28),

            Align(
              alignment: Alignment.centerRight,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _submitThemeForm,
                icon: const Text(
                  'Send',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                label: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}