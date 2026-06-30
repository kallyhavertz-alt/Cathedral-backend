import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  // 🟩 Grouped safely together at the top level
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  bool _isLiveStream = true;
  bool _isLoading = false;
  List<dynamic> _sharedUrlsLog = [];

   String _baseUrl = 'http://192.168.100.33:8080/api/services';

  @override
  void initState() {
    super.initState();
    _fetchSharedUrls();
  }

  @override
  void dispose() {
    // 🟩 Clean up ALL controllers safely here when leaving the page
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  // 📥 GET Request: Fetch existing service items from Spring Boot
  Future<void> _fetchSharedUrls() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));
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

            // 🔗 YOUTUBE URL INPUT (Fixed and restored!)
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
                  _isLiveStream = value; // 🟩 Dangerous line completely removed!
                });
              },
            ),
            const SizedBox(height: 12),

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
                          logItem['createdAtStr'] ?? logItem['date'] ?? '',
                          style: TextStyle(color: subTextColor, fontSize: 12),
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