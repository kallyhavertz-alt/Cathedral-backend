import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:untitled/session_manager.dart';

class ShareServiceLinkPage extends StatefulWidget {
  final Color primaryColor;

  const ShareServiceLinkPage({
    Key? key,
    required this.primaryColor,
  }) : super(key: key);

  @override
  State<ShareServiceLinkPage> createState() => _ShareServiceLinkPageState();
}

class _ShareServiceLinkPageState extends State<ShareServiceLinkPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  bool _isLiveStream = true;
  int _selectedDurationMinutes = 120; // ⏳ Default: 2 hours
  bool _isLoading = false;
  List<dynamic> _sharedUrlsLog = [];

  String _baseUrl = 'http://192.168.100.33:8080/api/v1';

  @override
  void initState() {
    super.initState();
    _fetchSharedUrls();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    super.dispose();
  }
  String _formatNotificationTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return "Recent";
    try {
      final DateTime notificationDate = DateTime.parse(isoString).toLocal();
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(notificationDate);

      if (difference.inMinutes < 1) {
        return "Just now";
      } else if (difference.inMinutes < 60) {
        return "${difference.inMinutes}m ago";
      } else if (difference.inHours < 24) {
        return "${difference.inHours}h ago";
      } else {
        return "${notificationDate.day}/${notificationDate.month}/${notificationDate.year}";
      }
    } catch (e) {
      return "Recent";
    }
  }

  Future<void> _fetchSharedUrls() async {
    final String? activeStaff = SessionManager.currentStaffId;
    if (activeStaff == null) return;
    try {
      final response = await http.get(Uri.parse('$_baseUrl/public/shared-urls?senderId=$activeStaff'));
      if (response.statusCode == 200) {
        setState(() {
          _sharedUrlsLog = json.decode(response.body);
        });
      }
    } catch (e) {
      debugPrint("Error fetching logs: $e");
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final String? activeStaff = SessionManager.currentStaffId;
    if (activeStaff == null) return;

    setState(() {
      _isLoading = true;
    });

    const String publishUrl = 'http://192.168.100.33:8080/api/v1/staff/media/publish';

    try {
      final response = await http.post(
        Uri.parse(publishUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'videoUrl': _urlController.text.trim(),
          'videoType': _isLiveStream ? 'LIVE' : 'PAST_SERVICE',
          'senderId': activeStaff,
          // ⏳ Send duration to backend if live (send '0' if it's already an archived/past video)
          'durationMinutes': _isLiveStream ? _selectedDurationMinutes.toString() : '0',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isLiveStream ? '🔴 Live broadcast published to Cathedral feeds!' : '📁 Past service archive added!'),
            backgroundColor: _isLiveStream ? Colors.red : Colors.green,
          ),
        );

        _titleController.clear();
        _descriptionController.clear();
        _urlController.clear();
        _fetchSharedUrls();
      } else {
        throw Exception("Server responded with status code: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish content: $e'), backgroundColor: Colors.red),
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
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Theme.of(context).cardColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: mainTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Share Link for live/recorded services',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: mainTextColor),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // 📋 TITLE INPUT
            TextFormField(
              controller: _titleController,
              style: TextStyle(color: mainTextColor),
              decoration: InputDecoration(
                labelText: 'TITLE',
                hintText: 'Enter a descriptive title (e.g., Cathedral Sunday Mass).',
                labelStyle: TextStyle(color: widget.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                hintStyle: TextStyle(color: subTextColor, fontSize: 13),
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.primaryColor, width: 2)),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 20),

            // 📝 DESCRIPTION INPUT
            TextFormField(
              controller: _descriptionController,
              style: TextStyle(color: mainTextColor),
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'DESCRIPTION',
                hintText: 'Enter a brief summary or sermon focus notes.',
                labelStyle: TextStyle(color: widget.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                hintStyle: TextStyle(color: subTextColor, fontSize: 13),
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.primaryColor, width: 2)),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a description' : null,
            ),
            const SizedBox(height: 20),

            // 🔗 YOUTUBE URL INPUT
            TextFormField(
              controller: _urlController,
              style: TextStyle(color: mainTextColor),
              decoration: InputDecoration(
                labelText: 'URL',
                hintText: 'Enter or paste youtube URL.',
                labelStyle: TextStyle(color: widget.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                hintStyle: TextStyle(color: subTextColor, fontSize: 13),
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.primaryColor, width: 2)),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter a URL';
                if (!v.contains('youtube.com') && !v.contains('youtu.be')) return 'Provide a valid YouTube link address';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // 🔴 LIVE TOGGLE SWITCH
            SwitchListTile(
              activeColor: Colors.red,
              contentPadding: EdgeInsets.zero,
              title: Row(
                children: [
                  Icon(Icons.radio_button_checked, color: _isLiveStream ? Colors.red : Colors.grey, size: 18),
                  const SizedBox(width: 8),
                  Text('Set as Live Broadcast Now', style: TextStyle(fontSize: 14, color: mainTextColor)),
                ],
              ),
              value: _isLiveStream,
              onChanged: (bool value) {
                setState(() {
                  _isLiveStream = value;
                });
              },
            ),
            const SizedBox(height: 12),

            // ⏳ DURATION SELECTOR (Animate its entry dynamically if stream is set to live)
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              child: _isLiveStream
                  ? Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: DropdownButtonFormField<int>(
                  value: _selectedDurationMinutes,
                  dropdownColor: Theme.of(context).cardColor,
                  style: TextStyle(color: mainTextColor),
                  decoration: InputDecoration(
                    labelText: 'LIVE STREAM EXPECTED DURATION',
                    labelStyle: TextStyle(color: widget.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.access_time_filled, color: widget.primaryColor),
                  ),
                  items: const [
                    DropdownMenuItem(value: 30, child: Text('30 Minutes')),
                    DropdownMenuItem(value: 60, child: Text('1 Hour')),
                    DropdownMenuItem(value: 90, child: Text('1.5 Hours')),
                    DropdownMenuItem(value: 120, child: Text('2 Hours')),
                    DropdownMenuItem(value: 180, child: Text('3 Hours')),
                    DropdownMenuItem(value: 240, child: Text('4 Hours')),
                  ],
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedDurationMinutes = newValue;
                      });
                    }
                  },
                ),
              )
                  : const SizedBox.shrink(),
            ),

            // 🚀 SUBMIT BUTTON
            Align(
              alignment: Alignment.centerRight,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: _submitForm,
                child: const Text('Share', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 10),

            // 🕒 HISTORY LOG
            Text(
              'URLs Shared',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: mainTextColor),
            ),
            const SizedBox(height: 12),

            if (_sharedUrlsLog.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('No previous links loaded.', style: TextStyle(color: subTextColor))),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _sharedUrlsLog.length,
                itemBuilder: (context, index) {
                  final logItem = _sharedUrlsLog[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${index + 1}. ', style: TextStyle(color: mainTextColor, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                logItem['title'] ?? 'Untitled Service',
                                style: TextStyle(color: mainTextColor, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              Text(
                                logItem['videoUrl'] ?? '',
                                style: TextStyle(color: Colors.blue.shade600, decoration: TextDecoration.underline, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _formatNotificationTime(logItem['created_at']),
                          style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}