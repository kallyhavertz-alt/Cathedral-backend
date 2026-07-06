import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:untitled/note_work_space_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:untitled/local_database_helper.dart';
import 'package:untitled/session_manager.dart';
import 'package:untitled/bb_text_formatter.dart';
import 'file_download_service.dart';
import 'deep_link_service.dart';
import 'package:http/http.dart' as http;

class EventDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> eventData;
  final Map<String, dynamic>? themeData;

  const EventDetailsScreen({
    Key? key,
    required this.eventData,
    this.themeData,
    Map<String, dynamic> eventItem = const {}, 
    dynamic themeDataExtra, 
  }) : super(key: key);

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool _isLiked = false;
  late int eventId;
  late String postType;

  late String eventTitle;
  late String description;
  late String scheduledAt;

  String? subService;
  String? midweekCategory;
  String? fileUrl;
  String? isFileType;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final bool isTheme = widget.themeData != null;
    final Map<String, dynamic> data = isTheme ? widget.themeData! : widget.eventData;

    eventId = data['id'] is int ? data['id'] : int.tryParse(data['id'].toString()) ?? 0;
    postType = isTheme ? 'CHURCH_THEME' : (data['postType'] ?? 'ANNOUNCEMENT').toString().toUpperCase();

    if (isTheme) {
       eventTitle = data['reading'] ?? 'Weekly Theme';
       description = data['themeText'] ?? '';
       scheduledAt = "Theme Active Period";
    } else {
       eventTitle = (data['title'] ?? data['eventTitle'] ?? 'Cathedral Event').toString();
       description = (data['content'] ?? data['description'] ?? 'Join us for our specialized service.').toString();

       if (data['formattedDate'] != null) {
         scheduledAt = '${data['formattedDate']}';
         if (data['formattedTime'] != null) {
           scheduledAt += ' at ${data['formattedTime']}';
         }
       } else {
         scheduledAt = (data['eventDate'] ?? 'Date Pending').toString();
       }
    }

    subService = data['subService'] != "NONE" ? data['subService'] : null;
    midweekCategory = data['midweekCategory'] != "NONE" ? data['midweekCategory'] : null;
    
    fileUrl = data['fileUrl'];
    isFileType = data['isFileType'];

    if (eventTitle == 'Cathedral Event' && eventId != 0 && !isTheme) {
       _fetchFullEventDetails();
    }

    _checkFavoriteStatus();
  }

  Future<void> _fetchFullEventDetails() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('http://192.168.100.33:8080/api/v1/posts/$eventId'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> fullData = json.decode(response.body);
        setState(() {
          eventTitle = fullData['title'] ?? eventTitle;
          description = fullData['content'] ?? description;
          if (fullData['formattedDate'] != null) {
            scheduledAt = '${fullData['formattedDate']} at ${fullData['formattedTime'] ?? ''}';
          }
          subService = fullData['subService'] != "NONE" ? fullData['subService'] : null;
          midweekCategory = fullData['midweekCategory'] != "NONE" ? fullData['midweekCategory'] : null;
          fileUrl = fullData['fileUrl'];
          isFileType = fullData['isFileType'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("🚨 Deep Link Data Fetch Error: $e");
      setState(() => _isLoading = false);
    }
  }

  Color _getEventThemeColor(bool isDark) {
    switch (postType) {
      case 'SUNDAY_SERVICE': return const Color(0xFF0D47A1);
      case 'MIDWEEK_EVENT': return const Color(0xFF2E7D32);
      case 'BISHOP_SPECIAL': return const Color(0xFFD4AF37);
      case 'ANNOUNCEMENT': return Colors.redAccent;
      case 'OTHER_MINISTRIES': return Colors.teal;
      case 'CHURCH_THEME': return Colors.amber;
      default: return isDark ? Colors.lightBlueAccent : const Color(0xFF0D47A1);
    }
  }

  IconData _getEventIcon() {
    switch (postType) {
      case 'SUNDAY_SERVICE': return Icons.church_rounded;
      case 'MIDWEEK_EVENT': return Icons.calendar_month_rounded;
      case 'BISHOP_SPECIAL': return Icons.gavel_rounded;
      case 'ANNOUNCEMENT': return Icons.campaign_rounded;
      case 'OTHER_MINISTRIES': return Icons.groups_rounded;
      case 'CHURCH_THEME': return Icons.auto_awesome_rounded;
      default: return Icons.event_note_rounded;
    }
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final int activeUserId = SessionManager.currentUserId;
      final db = await LocalDatabaseHelper.instance.database;
      final List<Map<String, dynamic>> match = await db.query(
        'local_notes',
        where: 'userId = ? AND eventId = ? AND isFavorite = 1',
        whereArgs: [activeUserId, eventId],
      );
      if (mounted && match.isNotEmpty) setState(() => _isLiked = true);
    } catch (e) {
      debugPrint('🚨 Favorite check failed: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final int activeUserId = SessionManager.currentUserId;
      final db = await LocalDatabaseHelper.instance.database;

      if (_isLiked) {
        await db.update('local_notes', {'isFavorite': 0}, where: 'userId = ? AND eventId = ?', whereArgs: [activeUserId, eventId]);
        setState(() => _isLiked = false);
      } else {
        final List<Map<String, dynamic>> existing = await db.query('local_notes', where: 'userId = ? AND eventId = ?', whereArgs: [activeUserId, eventId]);
        if (existing.isNotEmpty) {
          await db.update('local_notes', {'isFavorite': 1}, where: 'userId = ? AND eventId = ?', whereArgs: [activeUserId, eventId]);
        } else {
          await db.insert('local_notes', {
            'id': DateTime.now().millisecondsSinceEpoch * -1,
            'userId': activeUserId,
            'eventId': eventId,
            'eventTitle': eventTitle,
            'title': '$eventTitle (Favorite)',
            'content': description,
            'createdAt': DateTime.now().toIso8601String(),
            'syncStatus': 'LOCAL',
            'isFavorite': 1,
          });
        }
        setState(() => _isLiked = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to favorites!'), behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      debugPrint('🚨 Favorite toggle failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mainTextColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white70 : Colors.grey[800]!;
    final Color borderStrokeColor = isDark ? Colors.white38 : Colors.black26;
    final Color structuralIconColor = isDark ? Colors.white70 : Colors.black87;
    final Color accentThemeColor = _getEventThemeColor(isDark);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: structuralIconColor), onPressed: () => Navigator.pop(context)),
        title: Text('${postType.replaceAll('_', ' ')} DETAILS', style: TextStyle(color: mainTextColor, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.8)),
        actions: [
          if (fileUrl != null && fileUrl!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save_alt_rounded, color: Color(0xFF0D47A1)),
              onPressed: () {
                final String fullUrl = fileUrl!.startsWith('http') ? fileUrl! : 'http://192.168.100.33:8080$fileUrl';
                final String fileName = fileUrl!.split('/').last;
                FileDownloadService.downloadAndShare(
                  context, 
                  fullUrl, 
                  fileName.contains('.') ? fileName : "$fileName.${isFileType == "PDF" ? "pdf" : "jpg"}"
                );
              },
            ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderStrokeColor, width: 1.2),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05), blurRadius: 8, offset: const Offset(0, 4))]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_getEventIcon(), color: accentThemeColor, size: 22),
                      const SizedBox(width: 8),
                      Expanded(child: Text(eventTitle.toUpperCase(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: accentThemeColor, letterSpacing: 0.5))),
                    ],
                  ),
                  if (subService != null || midweekCategory != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentThemeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: accentThemeColor.withValues(alpha: 0.3)),
                      ),
                      child: Text((subService ?? midweekCategory)!.toUpperCase(), style: TextStyle(color: accentThemeColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const Divider(color: Colors.black12, height: 1),
                  const SizedBox(height: 14),
                  BBText(text: description, color: subTextColor, fontSize: 14),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Icons.watch_later_outlined, size: 16, color: isDark ? Colors.greenAccent : Colors.green[700]),
                      const SizedBox(width: 6),
                      Expanded(child: Text('Scheduled at: $scheduledAt', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.greenAccent : Colors.green[700]))),
                    ],
                  ),
                  const Divider(height: 28, color: Colors.black12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => NoteWorkspaceScreen(noteId: null, eventId: eventId, eventTitle: eventTitle, isEditing: false, initialTitle: '$eventTitle Reflection', initialContent: 'Regarding: "$eventTitle"\n\n'))),
                        child: Row(
                          children: [
                            Icon(Icons.add_box, color: structuralIconColor, size: 26),
                            const SizedBox(width: 8),
                            Text('Add Note for event', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: subTextColor)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border_rounded, color: _isLiked ? Colors.redAccent : structuralIconColor, size: 24), onPressed: _toggleFavorite),
                          IconButton(
                            icon: Icon(Icons.save_alt_rounded, color: structuralIconColor, size: 22),
                            onPressed: () {
                               if (fileUrl != null && fileUrl!.isNotEmpty) {
                                  final String fullUrl = fileUrl!.startsWith('http') ? fileUrl! : 'http://192.168.100.33:8080$fileUrl';
                                  final String fileName = fileUrl!.split('/').last;
                                  FileDownloadService.downloadAndShare(
                                    context, 
                                    fullUrl, 
                                    fileName.contains('.') ? fileName : "$fileName.${isFileType == "PDF" ? "pdf" : "jpg"}"
                                  );
                               } else {
                                  // Share text only if no file
                                  String opt = '';
                                  if (subService != null) opt = '📌 Service: $subService\n';
                                  if (midweekCategory != null) opt = '📌 Category: $midweekCategory\n';
                                  Share.share('ACK St. James Cathedral Update ⛪\n\n${eventTitle.toUpperCase()}\n$opt$description\n\n📅 Scheduled at: $scheduledAt\n\nShared via Cathedral App.');
                               }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text('≡', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: accentThemeColor)),
                const SizedBox(width: 8),
                Text('Event Metadata & Actions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.blue[300] : Colors.blue[900])),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                String dynamicMeta = '';
                if (subService != null) dynamicMeta = '[$subService] ';
                if (midweekCategory != null) dynamicMeta = '[$midweekCategory] ';
                Clipboard.setData(ClipboardData(text: '$eventTitle\n$dynamicMeta\n$description\n\nTime: $scheduledAt'));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied post content safely to your clip buffer!'), behavior: SnackBarBehavior.floating));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: borderStrokeColor, width: 1.2)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.copy_rounded, size: 16, color: mainTextColor),
                    const SizedBox(width: 8),
                    Text('Copy content', style: TextStyle(color: mainTextColor, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text('You can copy the content blocks above to seed updates into external personal tools!', style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}
