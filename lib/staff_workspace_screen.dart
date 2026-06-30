import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:untitled/church_schedules_screen.dart';
import 'package:untitled/share_service_url_page.dart';
import 'notification_service.dart';
import 'session_manager.dart';

/// 🎨 Custom Controller that parses [b], [r], [g] tags into inline native UI colors while typing!
class VividEditingController extends TextEditingController {
  final BuildContext context;
  VividEditingController({required this.context, String? text}) : super(text: text);

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color defaultColor = style?.color ?? (isDark ? Colors.white70 : Colors.black87);

    final Color blueColor = isDark ? Colors.lightBlueAccent : const Color(0xFF0D47A1);
    final Color redColor = isDark ? Colors.redAccent : const Color(0xFFC62828);
    final Color greenColor = isDark ? Colors.greenAccent : const Color(0xFF2E7D32);

    final List<TextSpan> children = [];
   // final RegExp regExp = RegExp(r'<(b)>(.*?)</\1>|([^<]+)', dotAll: true);
    final RegExp regExp = RegExp(r'\[([brg])\](.*?)\[\/\1\]|([^\[]+)', dotAll: true);
    final Iterable<Match> matches = regExp.allMatches(text);

    for (final Match match in matches) {
      if (match.group(3) != null) {
        children.add(TextSpan(text: match.group(3), style: style));
      } else {
        final String tag = match.group(1)!;
        final String innerText = match.group(2) ?? '';

        Color targetColor = defaultColor;
        FontWeight weight = FontWeight.normal;

        if (tag == 'b') { targetColor = blueColor; weight = FontWeight.bold; }
        else if (tag == 'r') { targetColor = redColor; weight = FontWeight.bold; }
        else if (tag == 'g') { targetColor = greenColor; weight = FontWeight.bold; }

        children.add(TextSpan(
          text: innerText,
          style: style?.copyWith(color: targetColor, fontWeight: weight) ??
              TextStyle(color: targetColor, fontWeight: weight),
        ));
      }
    }

    if (children.isEmpty) {
      return TextSpan(text: text, style: style);
    }
    return TextSpan(style: style, children: children);
  }
}

class StaffWorkspaceScreen extends StatefulWidget {
  const StaffWorkspaceScreen({Key? key}) : super(key: key);

  @override
  State<StaffWorkspaceScreen> createState() => _StaffWorkspaceScreenState();
}

class _StaffWorkspaceScreenState extends State<StaffWorkspaceScreen> {
  final TextEditingController _publicTitleController = TextEditingController();
  late VividEditingController _publicPostController;
  late VividEditingController _internalNoticeController;

  // 🎯 DROPDOWN STRINGS
  String? _selectedEventType;
  String? _selectedSundayService;
  String? _selectedMidweekCategory;

  // 📡 COMBINED LEDGER STATE (Aggregates posts and notices)
  List<dynamic> _sentHistory = [];
  bool _isLoadingHistory = true;

  // 🔄 UI SPINNER STATES TO LOCK CLICKS
  bool _isSubmittingPost = false;
  bool _isSubmittingNotice = false;

  // 📂 FILE PICKING STATE
  File? _selectedPostFile;
  String _fileTypeSelection = "TEXT";

  final String baseUrl = 'http://192.168.100.33:8080/api/v1';

  @override
  void initState() {
    super.initState();
    _publicPostController = VividEditingController(context: context);
    _internalNoticeController = VividEditingController(context: context);
    _fetchCombinedHistory();
  }

  Future<void> _pickFileForPost() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedPostFile = File(result.files.single.path!);
          String ext = result.files.single.extension?.toLowerCase() ?? '';
          _fileTypeSelection = (ext == 'pdf') ? "PDF" : "IMAGE";
        });
      }
    } catch (e) {
      print("🚨 File Pick Error: $e");
    }
  }
  String _stripFormattingTags(String input) {
    return input.replaceAll(RegExp(r'\[\/?([brg])\]'), '');
  }

  // Helper formatting prompt modal so users don't code tags manually
  void _openStyleInsertionDialog(TextEditingController controller, String tagCode, String colorName, Color themeColor) {
    final TextEditingController phraseController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Insert $colorName Text', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: phraseController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Type your styled phrase here...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: themeColor, foregroundColor: Colors.white),
            onPressed: () {
              final textToInsert = phraseController.text.trim();
              if (textToInsert.isNotEmpty) {
                final currentText = controller.text;
                final selection = controller.selection;
                final formatted = '[$tagCode]$textToInsert[/$tagCode]';

                int insertPos = selection.isValid ? selection.start : currentText.length;
                final newText = currentText.replaceRange(insertPos, selection.isValid ? selection.end : insertPos, formatted);

                controller.value = TextEditingValue(
                  text: newText,
                  selection: TextSelection.collapsed(offset: insertPos + formatted.length),
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text('Insert'),
          )
        ],
      ),
    );
  }

  //  SIMPLE TOUCH VISUAL FORMATTING RIBBON AT THE BOTTOM OF CONTAINER FIELD
  Widget _buildFormattingRibbon(TextEditingController controller) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black54.withValues(alpha: 0.04),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Row(
        children: [
          const Text('Text Style:  ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          _colorChip(label: 'Blue', color: const Color(0xFF0D47A1), onTap: () => _openStyleInsertionDialog(controller, 'b', 'Blue', const Color(0xFF0D47A1))),
          const SizedBox(width: 8),
          _colorChip(label: 'Red', color: const Color(0xFFC62828), onTap: () => _openStyleInsertionDialog(controller, 'r', 'Red', const Color(0xFFC62828))),
          const SizedBox(width: 8),
          _colorChip(label: 'Green', color: const Color(0xFF2E7D32), onTap: () => _openStyleInsertionDialog(controller, 'g', 'Green', const Color(0xFF2E7D32))),
        ],
      ),
    );
  }

  Widget _colorChip({required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // 📡 FETCH RECENT SUBMISSIONS MATCHING EXCLUSIVELY SENDER IDENTITY
  Future<void> _fetchCombinedHistory() async {
    setState(() => _isLoadingHistory = true);
    final String? activeStaff = SessionManager.currentStaffId;

    if (activeStaff == null) {
      setState(() => _isLoadingHistory = false);
      return;
    }

    try {
      final postsResponse = await http.get(Uri.parse('$baseUrl/staff/history/posts?senderId=$activeStaff'));
      final noticesResponse = await http.get(Uri.parse('$baseUrl/staff/history/notices?senderId=$activeStaff'));

      List<dynamic> combinedList = [];

      if (postsResponse.statusCode == 200) {
        final List<dynamic> posts = jsonDecode(postsResponse.body);
        combinedList.addAll(posts.map((e) => {...e, 'ledgerType': 'POST'}));
      }

      if (noticesResponse.statusCode == 200) {
        final List<dynamic> notices = jsonDecode(noticesResponse.body);
        combinedList.addAll(notices.map((e) => {...e, 'ledgerType': 'NOTICE', 'postType': 'STAFF_NOTICE', 'title': '📋 STAFF BRIEFING'}));
      }

      combinedList.sort((a, b) => (b['id'] ?? 0).compareTo(a['id'] ?? 0));

      setState(() {
        _sentHistory = combinedList;
        _isLoadingHistory = false;
      });
    } catch (_) {
      setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _deletePost(dynamic item) async {
    final String? activeStaff = SessionManager.currentStaffId;
    if (activeStaff == null) return;
    final int postId = item['id'];

    bool confirmDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Text('⚠️ Warning', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'NOTE: Deleting the post from this page clears the post from the users entirely.\n\nAre you sure you want to delete?',
            style: TextStyle(fontSize: 15, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    ) ?? false;

    if (!confirmDelete) return;

    try {
      final response = await http.delete(Uri.parse('$baseUrl/staff/delete-post/$postId?senderId=$activeStaff'));
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🗑️ Post deleted successfully!'), backgroundColor: Colors.green),
          );
        }
        _fetchCombinedHistory();
      }
    } catch (_) {}
  }

  // 📝 EDIT/UPDATE DIALOG MODAL LAYOUT
  void _showEditDialog(dynamic item) {
    final TextEditingController titleEditController = TextEditingController(text: item['title']);
    final VividEditingController contentEditController = VividEditingController(context: context, text: item['content']);
    String? currentSubService = item['subService'] == "NONE" ? null : item['subService'];

    bool isSavingSilently = false;
    bool isSavingAndPosting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final bool isDark = Theme.of(context).brightness == Brightness.dark;
            final bool isProcessing = isSavingSilently || isSavingAndPosting;

            Future<void> executeUpdate({required bool shouldBroadcast}) async {
              final String? activeStaff = SessionManager.currentStaffId;
              if (activeStaff == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Session expired. Log in again.'), backgroundColor: Colors.red));
                return;
              }

              setDialogState(() {
                if (shouldBroadcast) {
                  isSavingAndPosting = true;
                } else {
                  isSavingSilently = true;
                }
              });

              final Map<String, dynamic> updatePayload = {
                "postType": item['postType'],
                "subService": currentSubService ?? "NONE",
                "title": titleEditController.text.trim(),
                "content": contentEditController.text.trim(),
                "senderId": activeStaff,
              };

              try {
                print("📡 Updating Post: ${item['id']} - Broadcast: $shouldBroadcast");
                final response = await http.put(
                  Uri.parse('$baseUrl/staff/update-post/${item['id']}?broadcast=$shouldBroadcast'),
                  headers: {"Content-Type": "application/json"},
                  body: jsonEncode(updatePayload),
                );

                if (response.statusCode == 200) {
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Update successful!'), backgroundColor: Colors.green));
                  _fetchCombinedHistory();
                } else {
                  final errorMsg = jsonDecode(response.body)['message'] ?? 'Update failed.';
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $errorMsg'), backgroundColor: Colors.red));
                }
              } catch (e) {
                print("🚨 Update Exception: $e");
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error during update.'), backgroundColor: Colors.red));
              } finally {
                if (mounted) {
                  setDialogState(() {
                    isSavingSilently = false;
                    isSavingAndPosting = false;
                  });
                }
              }
            }

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              title: Text('Modify ${item['postType'].toString().replaceAll('_', ' ')}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item['postType'] == 'SUNDAY_SERVICE') ...[
                      DropdownButtonFormField<String>(
                        initialValue: currentSubService,
                        hint: const Text('Sub Service'),
                        items: ['Kikuyu Service', 'Kiswahili Service', 'English Service', 'Main Kikuyu Service']
                            .map((sub) => DropdownMenuItem(value: sub, child: Text(sub)))
                            .toList(),
                        onChanged: isProcessing ? null : (val) => currentSubService = val,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      enabled: !isProcessing,
                      controller: titleEditController,
                      decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        TextField(
                          enabled: !isProcessing,
                          controller: contentEditController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                              labelText: 'Content Block',
                              border: OutlineInputBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12)))
                          ),
                        ),
                        _buildFormattingRibbon(contentEditController),
                      ],
                    ),
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actions: [
                TextButton(
                  onPressed: isProcessing ? null : () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF0D47A1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: isProcessing ? null : () => executeUpdate(shouldBroadcast: false),
                      child: isSavingSilently
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Save Changes', style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: isProcessing ? null : () => executeUpdate(shouldBroadcast: true),
                      child: isSavingAndPosting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save & Post', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitPublicPost() async {
    if (_selectedEventType == null || _publicTitleController.text.trim().isEmpty || _publicPostController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete the Type, Title, and Content fields.')),
      );
      return;
    }

    final String? activeStaff = SessionManager.currentStaffId;
    if (activeStaff == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Session Error: Staff identity not found. Please log in again.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmittingPost = true);

    try {
      var uri = Uri.parse('$baseUrl/staff/create-post');
      var request = http.MultipartRequest('POST', uri);

      request.fields['postType'] = _selectedEventType!;
      request.fields['subService'] = _selectedSundayService ?? "NONE";


      request.fields['midweekCategory'] = _selectedMidweekCategory ?? "NONE";

      request.fields['title'] = _publicTitleController.text.trim();
      request.fields['content'] = _publicPostController.text.trim();
      request.fields['senderId'] = activeStaff;
      request.fields['isFileType'] = _fileTypeSelection;

      if (_selectedPostFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            _selectedPostFile!.path,
          ),
        );
      }

      print("📡 Dispatching Multipart Post Request to: $uri");
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("📡 Server Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎉 Post published & notification sent!'), backgroundColor: Colors.green));
          _publicTitleController.clear();
          _publicPostController.clear();
          setState(() {
            _selectedEventType = null;
            _selectedSundayService = null;

            // 🟩 RESET FORM STATE: Clear state tracker on successful upload
            _selectedMidweekCategory = null;

            _selectedPostFile = null;
            _fileTypeSelection = "TEXT";
          });
          _fetchCombinedHistory();
        }
      } else {
        if (mounted) {
          final errorMsg = jsonDecode(response.body)['message'] ?? 'Server rejected the post.';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $errorMsg'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      print("🚨 POST Exception: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error dispatching payload.'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmittingPost = false);
    }
  }

  Future<void> _submitInternalNotice() async {
    if (_internalNoticeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter content for the notice.')));
      return;
    }

    final String? activeStaff = SessionManager.currentStaffId;
    if (activeStaff == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Session Error: Staff identity not found.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmittingNotice = true);

    final Map<String, dynamic> payload = {
      "content": _internalNoticeController.text.trim(),
      "senderId": activeStaff,
    };

    try {
      print("📡 Dispatching Notice Payload: ${jsonEncode(payload)}");
      final response = await http.post(
        Uri.parse('$baseUrl/staff/create-notice'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      print("📡 Notice Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🟩 Notice dispatched to staff channel.'), backgroundColor: Colors.green));
          _internalNoticeController.clear();
          _fetchCombinedHistory();
        }
      } else {
        if (mounted) {
          final errorMsg = jsonDecode(response.body)['message'] ?? 'Server rejected the notice.';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $errorMsg'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      print("🚨 NOTICE Exception: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error dispatching notice.'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmittingNotice = false);
    }
  }

  @override
  void dispose() {
    _publicTitleController.dispose();
    _publicPostController.dispose();
    _internalNoticeController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    await NotificationService().unsubscribeFromStaffUpdates();
    await SessionManager.clearStaffSession();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = const Color(0xFF0D47A1);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : primaryColor,
          foregroundColor: Colors.white,
          title: const Text('STAFF WORKSPACE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.1)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Opt Out',
              onPressed: _handleLogout,
            )
          ],
          bottom: TabBar(
            indicatorColor: isDark ? Colors.greenAccent : Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            tabs: const [
              Tab(text: 'POST'),
              Tab(text: 'NOTICE'),
              Tab(text: 'SENT'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPostTab(isDark, primaryColor),
            _buildNoticeTab(isDark, primaryColor),
            _buildSentTab(isDark, primaryColor),
          ],
        ),
      ),
    );
  }
// ==================== 🟥 TAB 1: PUBLIC POST VIEW ====================
  Widget _buildPostTab(bool isDark, Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🟩 Row layout to sandwich the "Add Service URL" button right beside the description text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Post an event for everyone to see',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey),
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                icon: const Icon(Icons.video_call_rounded, size: 20),
                label: const Text('Add Service URL', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShareServiceLinkPage(primaryColor: primaryColor),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _selectedEventType,
            hint: const Text('Event Type'),
            decoration: _buildInputDecoration(isDark, Icons.arrow_drop_down_circle_outlined),
            items: const [
              DropdownMenuItem(value: 'ANNOUNCEMENT', child: Text('Announcement')),
              DropdownMenuItem(value: 'BISHOP_SPECIAL', child: Text('Bishop Schedule')),
              DropdownMenuItem(value: 'SUNDAY_SERVICE', child: Text('Sunday Service')),
              DropdownMenuItem(value: 'OTHER_MINISTRIES', child: Text('Other Ministries')),
              DropdownMenuItem(value: 'MIDWEEK_EVENT', child: Text('Mid-Week Event')),
            ],
            onChanged: _isSubmittingPost ? null : (value) {
              setState(() {
                _selectedEventType = value;
                // Clean up opposing state flags so fields don't bleed hidden values
                if (value != 'SUNDAY_SERVICE') _selectedSundayService = null;
                if (value != 'MIDWEEK_EVENT') _selectedMidweekCategory = null;
              });
            },
          ),

          // ⛪ CONDITIONAL BLOCK: Sunday Service Sub-Services
          if (_selectedEventType == 'SUNDAY_SERVICE') ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedSundayService, // Changed from initialValue to value for safe state clearing
              hint: const Text('Select Sub Service'),
              decoration: _buildInputDecoration(isDark, Icons.church_outlined),
              items: ['Kikuyu Service', 'Kiswahili Service', 'English Service', 'Main Kikuyu Service']
                  .map((sub) => DropdownMenuItem(value: sub, child: Text(sub)))
                  .toList(),
              onChanged: _isSubmittingPost ? null : (value) => setState(() => _selectedSundayService = value),
            ),
          ],

          // 📅 CONDITIONAL BLOCK: Mid-Week Event Sub-Categories
          if (_selectedEventType == 'MIDWEEK_EVENT') ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedMidweekCategory,
              hint: const Text('Select Mid-Week Category'),
              decoration: _buildInputDecoration(isDark, Icons.calendar_month_outlined),
              items: const [
                DropdownMenuItem(value: 'Daily prayers', child: Text('Daily prayers')),
                DropdownMenuItem(value: 'Wednesday Holy Communion ', child: Text('Wednesday Holy Communion')),
                DropdownMenuItem(value: 'Friday Hymnos', child: Text('Friday Hymnos')),
                DropdownMenuItem(value: 'others', child: Text('Others')),
              ],
              onChanged: _isSubmittingPost ? null : (value) => setState(() => _selectedMidweekCategory = value),
            ),
          ],

          const SizedBox(height: 20),
          const Text('Event Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            enabled: !_isSubmittingPost,
            controller: _publicTitleController,
            decoration: InputDecoration(
              hintText: 'e.g., Combined Youth Rally',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Text('Content', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Column(
            children: [
              TextField(
                enabled: !_isSubmittingPost,
                controller: _publicPostController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Remember to include the date when the event will take place and share the venue also.',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  border: const OutlineInputBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                ),
              ),
              _buildFormattingRibbon(_publicPostController),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Attachment (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _isSubmittingPost ? null : _pickFileForPost,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white12 : Colors.black12, style: BorderStyle.solid),
              ),
              child: _selectedPostFile == null
                  ? Row(
                children: [
                  Icon(Icons.cloud_upload_outlined, color: primaryColor),
                  const SizedBox(width: 12),
                  const Text('Tap to attach an image that will be visible as post background', style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              )
                  : Row(
                children: [
                  Icon(_fileTypeSelection == "PDF" ? Icons.picture_as_pdf : Icons.image, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedPostFile!.path.split('/').last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 20),
                    onPressed: () => setState(() => _selectedPostFile = null),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: _isSubmittingPost
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0))
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(_isSubmittingPost ? 'Sending...' : 'Send'),
              onPressed: _isSubmittingPost ? null : _submitPublicPost,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNoticeTab(bool isDark, Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Post a notice to notify the other Staff members.',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChurchSchedulesScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_month_rounded, size: 16, color: primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        'Schedules',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Content:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Column(
            children: [
              TextField(
                enabled: !_isSubmittingNotice,
                controller: _internalNoticeController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: "Don't forget to add the time when it will take place and also the facilitators.",
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  border: const OutlineInputBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                ),
              ),
              _buildFormattingRibbon(_internalNoticeController),
            ],
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: _isSubmittingNotice
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0))
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(_isSubmittingNotice ? 'Sending...' : 'Send'),
              onPressed: _isSubmittingNotice ? null : _submitInternalNotice,
            ),
          )
        ],
      ),
    );
  }

  // ==================== 🟦 TAB 3: HISTORICAL SENT LEDGER ====================
  Widget _buildSentTab(bool isDark, Color primaryColor) {
    print("MASTER PAYLOAD: $_sentHistory");
    if (_isLoadingHistory) return const Center(child: CircularProgressIndicator());
    if (_sentHistory.isEmpty) return const Center(child: Text('No messages sent via this channel yet.'));

    return RefreshIndicator(
      onRefresh: _fetchCombinedHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sentHistory.length,
        itemBuilder: (context, index) {
          final item = _sentHistory[index];
          final bool isNotice = item['ledgerType'] == 'NOTICE';

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${index + 1}. Item ID: #${item['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey)),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: isNotice ? Colors.deepOrange.withValues(alpha: 0.1) : primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                            child: Text(isNotice ? 'STAFF NOTICE' : item['postType'].toString().replaceAll('_', ' '), style: TextStyle(color: isNotice ? Colors.deepOrange : primaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          if (!isNotice)
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert_rounded, size: 20),
                              onSelected: (action) {
                                if (action == 'edit') { _showEditDialog(item); }
                                else if (action == 'delete') { _deletePost(item); }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, color: Colors.blue, size: 18), SizedBox(width: 8), Text('Edit Post')])),
                                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_forever_rounded, color: Colors.red, size: 18), SizedBox(width: 8), Text('Delete')])),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                  if (item['subService'] != null && item['subService'] != "NONE") ...[
                    const SizedBox(height: 4),
                    Text('⛪ ${item['subService']}', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey, fontSize: 13)),
                  ],
                  const SizedBox(height: 8),
                  Text(item['title'] ?? 'Internal Staff Update', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  BBTextFormatter.parseToRichText(context, item['content'] ?? ''),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('🕒 ${item['formattedTime'] ?? 'Now'} | 📅 ${item['formattedDate'] ?? 'Today'}', style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500)),
                      const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 16),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _buildInputDecoration(bool isDark, IconData prefixIcon) {
    return InputDecoration(prefixIcon: Icon(prefixIcon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white);
  }
}

class BBTextFormatter {
  static Widget parseToRichText(BuildContext context, String input, {double fontSize = 13.0, double height = 1.3}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color defaultColor = isDark ? Colors.white70 : Colors.black87;
    final Color blueColor = isDark ? Colors.lightBlueAccent : const Color(0xFF0D47A1);
    final Color redColor = isDark ? Colors.redAccent : const Color(0xFFC62828);
    final Color greenColor = isDark ? Colors.greenAccent : const Color(0xFF2E7D32);

    final List<TextSpan> spans = [];
     RegExp regExp = RegExp(r'\[([brg])\](.*?)\[\/\1\]|([^\[]+)', dotAll: true);
   // final RegExp regExp = RegExp(r'<(b)>(.*?)</\1>|([^<]+)', dotAll: true);
    final Iterable<Match> matches = regExp.allMatches(input);

    for (final Match match in matches) {
      if (match.group(3) != null) {
        spans.add(TextSpan(text: match.group(3), style: TextStyle(color: defaultColor, fontSize: fontSize, height: height)));
      } else {
        final String? tag = match.group(1);
        final String textContent = match.group(2) ?? '';
        Color targetColor = defaultColor;
        FontWeight weight = FontWeight.normal;

        if (tag == 'b') { targetColor = blueColor; weight = FontWeight.bold; }
        else if (tag == 'r') { targetColor = redColor; weight = FontWeight.bold; }
        else if (tag == 'g') { targetColor = greenColor; weight = FontWeight.bold; }

        spans.add(TextSpan(text: textContent, style: TextStyle(color: targetColor, fontWeight: weight, fontSize: fontSize, height: height)));
      }
    }
    return RichText(text: TextSpan(children: spans));
  }
}