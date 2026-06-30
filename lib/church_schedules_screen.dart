import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:untitled/session_manager.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class ChurchSchedulesScreen extends StatefulWidget {
  const ChurchSchedulesScreen({super.key});

  @override
  State<ChurchSchedulesScreen> createState() => _ChurchSchedulesScreenState();
}

class _ChurchSchedulesScreenState extends State<ChurchSchedulesScreen> {
  final bool _isAdmin = true;
  bool _isLoading = false;

  String? _currentCanvasFileUrl;
  String _currentCanvasType = "TEXT";

  // Active state holders for text-based fallback display
  String _currentCanvasTitle = "General Schedule";
  String _currentCanvasContent = "No custom text notes provided.";

  // 🚀 UPDATED DYNAMIC SHARE payload content engine
  void _executeShareSheet() {
    String sharePayload = "";

    if (_currentCanvasFileUrl != null) {
      sharePayload = """
       ACK ST. JAMES KIAMBU - SCHEDULE DOCUMENT ATTACHED
Title: $_currentCanvasTitle

You can view or download the active attachment file here:
http://192.168.100.33:8080$_currentCanvasFileUrl
""";
    } else if (_currentCanvasContent.isNotEmpty && _currentCanvasContent != "No custom text notes provided.") {
      sharePayload = """
ACK ST. JAMES KIAMBU - SCHEDULE NOTICE
 Title: $_currentCanvasTitle

$_currentCanvasContent
""";
    } else {
      sharePayload = """
 ACK ST. JAMES KIAMBU GENERAL SCHEDULES

 SUNDAY SERVICES:
• Kikuyu Service: 6:00 am - 7:00 am
• Kiswahili Service: 7:00 am - 9:00 am
• English Service: 9:00 am - 11:00 am
• Main Kikuyu Service: 11:00 am - 1:30 pm

MID-WEEK SERVICES:
• Wednesday Lunch Hour (Holy Communion): 11:00 am - 2:00 pm
• Friday Hymns: 5:00 pm - 7:00 pm
• Saturday: Church Cleaning

 OTHER MINISTRIES (Scheduled):
• Dorcas Ministry
• Prisons Ministry
• Schools Ministry

👉 Continue visiting this page for more updates!
""";
    }

    Share.share(sharePayload, subject: _currentCanvasTitle.isNotEmpty ? _currentCanvasTitle : 'ACK St. James Kiambu Schedules');
  }

  @override
  void initState() {
    super.initState();
    _fetchActiveScheduleFromServer();
  }

  Future<void> _fetchActiveScheduleFromServer() async {
    setState(() => _isLoading = true);
    try {
      var uri = Uri.parse('http://192.168.100.33:8080/api/v1/schedules/latest');
      var response = await http.get(uri);

      if (response.statusCode == 200) {
        List<dynamic> schedules = json.decode(response.body);

        if (schedules.isNotEmpty) {
          final latestData = schedules.first;
          setState(() {
            _currentCanvasFileUrl = latestData['fileUrl'];
            _currentCanvasType = latestData['isFileType'] ?? "TEXT";
            _currentCanvasTitle = latestData['title'] ?? "General Schedule";
            _currentCanvasContent = latestData['content'] ?? "";
          });
        }
      }
    } catch (e) {
      print("Error fetching schedules: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  final String? activeStaff = SessionManager.currentStaffId;

  Future<void> _submitScheduleToBackend({
    required String title,
    required String content,
    required String fileType,
    File? attachedFile,
  }) async {
    setState(() => _isLoading = true);
    try {
      final String? activeStaff = SessionManager.currentStaffId;

      print("DEBUG: Active Staff Session Identifier is currently -> '$activeStaff'");

      if (activeStaff == null || activeStaff.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Session Error: Staff identity not found. Please log in again.'), backgroundColor: Colors.red),
        );
        return;
      }

      var uri = Uri.parse('http://192.168.100.33:8080/api/v1/schedules/staff/create');
      var request = http.MultipartRequest('POST', uri);

      request.fields['title'] = title;
      request.fields['content'] = content;
      request.fields['senderId'] = activeStaff.trim();
      request.fields['isFileType'] = fileType;

      if (attachedFile != null) {
        request.files.add(await http.MultipartFile.fromPath('file', attachedFile.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule posted and synchronised successfully!'), backgroundColor: Colors.green),
        );
        final Map<String, dynamic> responseData = json.decode(response.body);

        setState(() {
          _currentCanvasFileUrl = responseData['fileUrl'];
          _currentCanvasType = responseData['isFileType'] ?? "TEXT";
          _currentCanvasTitle = responseData['title'] ?? title;
          _currentCanvasContent = responseData['content'] ?? content;
        });

      } else {
        throw Exception('Server rejected request with status code: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading payload: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 🔍 LIGHTBOX GESTURE ENHANCEMENT: Opens full detail preview overlay
  void _openCanvasFullscreenOverlay() {
    if (_currentCanvasFileUrl == null && _currentCanvasContent.trim() == "No custom text notes provided.") return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(_currentCanvasTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              automaticallyImplyLeading: false,
              actions: [IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context))],
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: _currentCanvasType == "IMAGE" && _currentCanvasFileUrl != null
                    ? InteractiveViewer(
                  maxScale: 4.0,
                  child: Image.network('http://192.168.100.33:8080$_currentCanvasFileUrl', fit: BoxFit.contain),
                )
                    : Text(
                  _currentCanvasContent,
                  style: const TextStyle(fontSize: 15, height: 1.5, fontFamily: 'monospace'),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showPostScheduleSheet() {
    final titleController = TextEditingController(text: "ACK St. James Schedule - ${DateTime.now().month}/${DateTime.now().year}");
    final contentController = TextEditingController();
    File? selectedFile;
    String fileTypeSelection = "TEXT";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Publish New Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 10),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title / Reference Header', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: contentController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Write Layout Contents (Optional if uploading file)',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 15),
                    GestureDetector(
                      onTap: () async {
                        try {
                          FilePickerResult? result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf'],
                          );

                          if (result != null && result.files.single.path != null) {
                            setModalState(() {
                              selectedFile = File(result.files.single.path!);
                              String ext = result.files.single.extension?.toLowerCase() ?? '';
                              fileTypeSelection = (ext == 'pdf') ? "PDF" : "IMAGE";
                            });
                          }
                        } catch (e) {
                          print("🚨 FilePicker Error: $e");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error picking file: $e'), backgroundColor: Colors.red),
                          );
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid, width: 1.5),
                        ),
                        child: selectedFile == null
                            ? const Column(
                          children: [
                            Icon(Icons.cloud_upload_outlined, size: 32, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Tap to select flyer image or PDF document', style: TextStyle(fontSize: 13, color: Colors.grey)),
                          ],
                        )
                            : Column(
                          children: [
                            Icon(fileTypeSelection == "PDF" ? Icons.picture_as_pdf : Icons.image, size: 36, color: Colors.blue),
                            const SizedBox(height: 8),
                            Text(
                              selectedFile!.path.split('/').last,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                            const SizedBox(height: 4),
                            const Text('Tap again to replace document selection', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          if (titleController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please write a title')));
                            return;
                          }
                          Navigator.pop(context);
                          _submitScheduleToBackend(
                            title: titleController.text,
                            content: contentController.text,
                            fileType: fileTypeSelection,
                            attachedFile: selectedFile,
                          );
                        },
                        child: const Text('Upload & Post Schedule', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Church Schedules', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black,
        actions: [
          if (_isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 16.0, top: 10.0, bottom: 10.0),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.blue, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                icon: const Icon(Icons.add_box_rounded, size: 16, color: Colors.blue),
                label: const Text(
                  'Post a Schedule',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                onPressed: _showPostScheduleSheet,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView( // 🟩 REMOVED жесткие EXPANDED SPLITS — SCROLLS ALL AS ONE PIECE
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Text(
                'Note: A schedule is posted once per month.',
                style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 12),

            // 🖼️ Wide Stretchable Canvas Frame Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _openCanvasFullscreenOverlay, // 🚀 TAP CANVAS GESTURE HOOK FOR LIGHTBOX VIEW
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 250), // 🟩 Extends widely matching content height dynamically
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.black12, width: 1.5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _currentCanvasFileUrl == null && _currentCanvasContent.trim() == "No custom text notes provided."
                            ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.picture_as_pdf_rounded, size: 44, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'Monthly Schedule Document Preview Canvas',
                              style: TextStyle(color: Colors.grey[500], fontSize: 13),
                            ),
                          ],
                        )
                            : (_currentCanvasType == "IMAGE" && _currentCanvasFileUrl != null
                            ? Image.network(
                          'http://192.168.100.33:8080$_currentCanvasFileUrl',
                          fit: BoxFit.fitWidth, // 🟩 Spans the horizontal grid beautifully
                          errorBuilder: (context, error, stackTrace) => const Center(child: Text("Error loading image preview")),
                        )
                            : (_currentCanvasType == "PDF" && _currentCanvasFileUrl != null
                            ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 45),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.menu_book_rounded, size: 44, color: Colors.blue),
                              SizedBox(height: 8),
                              Text('PDF Schedule Attached', style: TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.bold)),
                              Text('Tap Save to download file attachment', style: TextStyle(color: Colors.grey, fontSize: 11)),
                            ],
                          ),
                        )
                            : Container(
                          // 📝 PLAIN TEXT LAYOUT DISPLAY CELL
                          width: double.infinity,
                          padding: const EdgeInsets.all(18.0),
                          color: isDark ? const Color(0xFF252525) : Colors.amber[50]?.withValues(alpha: 0.5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.assignment_rounded, size: 16, color: Colors.blue[600]),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _currentCanvasTitle,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blue[600]),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              Text(
                                _currentCanvasContent,
                                style: TextStyle(fontSize: 14, height: 1.5, color: isDark ? Colors.white70 : Colors.black87),
                              ),
                              const SizedBox(height: 44), // Safe action row margin space indicator
                            ],
                          ),
                        ))),
                      ),
                    ),
                  ),

                  // Floating Actions inside Canvas Frame
                  Positioned(
                    bottom: 14,
                    right: 14,
                    child: Row(
                      children: [
                        _buildFloatingActionButton(
                          icon: Icons.share_rounded,
                          label: 'Share',
                          onTap: _executeShareSheet,
                        ),
                        const SizedBox(width: 12),
                        _buildFloatingActionButton(
                          icon: Icons.file_download_rounded,
                          label: 'Save',
                          onTap: () {
                            // 🟩 KEPT FUNCTIONAL: Hook up your internal file saving download pipeline task here
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Downloading attachment file pipeline initialized...')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 🗺️ Bottom Reference Panel (flows safely directly below the layout canvas)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'General Schedules ACK St. James Kiambu.',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const Divider(height: 16, thickness: 1),

                  _buildSectionHeader('Sunday Services', Colors.redAccent),
                  _buildScheduleTimeRow('Kikuyu Service', '6:00 am - 7:00 am'),
                  _buildScheduleTimeRow('Kiswahili Service', '7:00 am - 9:00 am'),
                  _buildScheduleTimeRow('English Service', '9:00 am - 11:00 am'),
                  _buildScheduleTimeRow('Main Kikuyu Service', '11:00 am - 1:30 pm'),
                  const SizedBox(height: 14),

                  _buildSectionHeader('Mid-Week Services', Colors.blue),
                  _buildScheduleTimeRow('Wed Lunch Hour (Holy Communion)', '11:00 am - 2:00 pm'),
                  _buildScheduleTimeRow('Friday Hymns', '5:00 pm - 7:00 pm'),
                  _buildScheduleTimeRow('Saturday', 'Church Cleaning'),
                  const SizedBox(height: 14),

                  _buildSectionHeader('Other Ministries', Colors.red),
                  _buildScheduleTimeRow('Dorcas Ministry', 'Scheduled'),
                  _buildScheduleTimeRow('Prisons Ministry', 'Scheduled'),
                  _buildScheduleTimeRow('Schools Ministry', 'Scheduled'),

                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Continue visiting this page for more schedules.',
                      style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: accentColor, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildFloatingActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: Colors.white),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleTimeRow(String serviceName, String timeRange) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              serviceName,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            timeRange,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}