import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart'; // 🚀 Added for Share functionality
import 'dart:convert';
import 'package:untitled/main.dart';
import 'package:untitled/note_work_space_screen.dart';
import 'package:untitled/session_manager.dart';
import 'package:untitled/local_database_helper.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<dynamic> _displayNotes = [];
  bool _isLoading = true;
  bool _isOfflineMode = false;

  String _formatPostgresDate(dynamic rawDate) {
    if (rawDate == null) return 'Recent Note';
    final String rawDateString = rawDate.toString();
    if (rawDateString.isEmpty) return 'Recent Note';

    try {
      DateTime parsedDate = DateTime.parse(rawDateString);
      List<String> months = ['Jan', 'Feb', 'March', 'April', 'May', 'June', 'July', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec'];
      return '${parsedDate.day} ${months[parsedDate.month - 1]} ${parsedDate.year}';
    } catch (e) {
      return 'Recent Note';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadNotesDataEngine();
  }

  // 🔄 SMART DATA ENGINE: Fetches from network if online, falls back to local cache if offline
  Future<void> _loadNotesDataEngine() async {
    final int activeId = SessionManager.currentUserId;
    final String dynamicFetchUrl = 'http://10.34.113.23:8080/api/notes/user/$activeId';

    setState(() => _isLoading = true);

    try {
      print('📡 Attempting network fetch from backend...');
      final response = await http.get(Uri.parse(dynamicFetchUrl)).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> networkNotes = jsonDecode(response.body);
        print('✅ Server pull successful. Caching ${networkNotes.length} rows to SQLite.');

        // Save to native local storage device
        await LocalDatabaseHelper.instance.refreshLocalCache(networkNotes);
        _isOfflineMode = false;
      }
    } catch (e) {
      print('🚨 Offline Mode Active: Network pull failed ($e). Reading device cache instead.');
      _isOfflineMode = true;
    }

    // Always source UI display records straight from local engine storage for consistent tracking
    final localNotes = await LocalDatabaseHelper.instance.getUserNotes(activeId);
    setState(() {
      _displayNotes = List.from(localNotes); // Create modifiable list copy
      _isLoading = false;
    });

    // Run a background upload check if we are online to clear any cached pending updates
    if (!_isOfflineMode) {
      _synchronizePendingOfflineNotes();
    }
  }

  // 🚀 BACKGROUND SYNC ENGINE
  Future<void> _synchronizePendingOfflineNotes() async {
    final pendingNotes = await LocalDatabaseHelper.instance.getPendingNotes();
    if (pendingNotes.isEmpty) return;

    print('🔄 Found ${pendingNotes.length} offline notes waiting to sync. Uploading...');
    for (var note in pendingNotes) {
      try {
        final url = 'http://10.34.113.23:8080/api/notes/add/${note['userId']}';
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': note['title'],
            'content': note['content'],
            'eventId': note['eventId'],
            'eventTitle': note['eventTitle'],
          }),
        );

        if (response.statusCode == 200) {
          // Sync complete, clear temporary cache copy row safely
          await LocalDatabaseHelper.instance.deleteNote(note['id']);
          print('✅ Synced offline note "${note['title']}" to production PostgreSQL server.');
        }
      } catch (e) {
        print('🚨 Sync upload failed re-attempt for note ID: ${note['id']}. Waiting for next network loop.');
        break;
      }
    }
  }

  // 🗑️ DOMINION ACTION: Delete a note with an elegant bottom confirmation sheet
  void _showDeleteConfirmationSheet(Map<String, dynamic> note) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delete this note?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'It will be permanently deleted from your device.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    // ❌ CANCEL BUTTON
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.black87),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 🗑️ CONFIRM PERMANENT DELETE BUTTON
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close sheet
                          final dynamic targetId = note['id'];
                          print('🎯 Confirm clicked inside sheet for Note ID: $targetId');
                          _executeFinalDestruction(targetId); // Run actual deletion
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 💥 The actual execution mechanism that drops the row from storage
  Future<void> _executeFinalDestruction(dynamic noteId) async {
    if (noteId == null) return;

    // Parse to integer safely for SQLite operations
    final int targetId = int.parse(noteId.toString());
    print('🗑️ Starting permanent purge execution for Target ID: $targetId');

    try {
      // 1. Remove from local device storage cache securely using parsed target integer
      await LocalDatabaseHelper.instance.deleteNote(targetId);
      print('✅ Wiped successfully from SQLite storage engine.');
    } catch(e) {
      print('🚨 SQLite deletion encounter: $e');
    }

    // 2. Instantly drop from screen view state using string tracking checks to avoid type blocks
    setState(() {
      _displayNotes.removeWhere((element) => element['id'].toString() == targetId.toString());
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note permanently deleted.', style: TextStyle(fontSize: 13))),
      );
    }

    // 3. Fire backend destruction script if online (Ignore if negative temporary local ID)
    if (!_isOfflineMode && targetId > 0) {
      try {
        final url = 'http://10.34.113.23:8080/api/notes/delete/$targetId';
        final response = await http.delete(Uri.parse(url)).timeout(const Duration(seconds: 4));
        print('🗑️ Server deletion execution returned status frame: ${response.statusCode}');
        print('🗑️ System dropped backend system global ID: $targetId');
      } catch (e) {
        print('🚨 Backend deletion broadcast failed ($e). Local destruction intact.');
      }
    }
  }

  // 📤 DOMINION ACTION: Share note data natively using native sheet protocols
  void _handleShareNote(Map<String, dynamic> note) {
    final String shareBody = 'Reflections from: ${note['eventTitle'] ?? 'Personal Reflections'}\n\n'
        'Title: ${note['title'] ?? 'Untitled'}\n'
        'Date: ${_formatPostgresDate(note['createdAt'] ?? note['dateCreated'] ?? note['date'])}\n\n'
        '${note['content'] ?? ''}';

    Share.share(shareBody, subject: note['title'] ?? 'Cathedral Service Insights');
  }

  void _navigateToWorkspace(Map<String, dynamic> note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteWorkspaceScreen(
          noteId: note['id'],
          eventId: note['eventId'] ?? 1,
          eventTitle: note['eventTitle'] ?? 'Cathedral Service',
          isEditing: true,
          initialTitle: note['title'] ?? '',
          initialContent: note['content'] ?? '',
        ),
      ),
    ).then((value) => _loadNotesDataEngine());
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 INDEPENDENT STREAM SEGREGATION
    final List<dynamic> savedNotesList = _displayNotes.where((note) {
      final String title = (note['eventTitle'] ?? '').toString();
      return title.isEmpty || title == 'Personal Note' || title == 'Cathedral Service' || title == 'General Sermon Note';
    }).toList();

    final List<dynamic> eventReadingsList = _displayNotes.where((note) {
      final String title = (note['eventTitle'] ?? '').toString();
      return title.isNotEmpty && title != 'Personal Note' && title != 'Cathedral Service' && title != 'General Sermon Note';
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
          },
        ),
        title: Row(
          children: [
            const Text('My Notes', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 22)),
            if (_isOfflineMode) ...[
              const SizedBox(width: 8),
              const Icon(Icons.cloud_off, color: Colors.redAccent, size: 18),
            ]
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔍 Search Bar Field
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black54, width: 1.2),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Search for notes and readings',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Colors.black54, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // SECTION 1 HEADER
                const Row(
                  children: [
                    Text('=', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    SizedBox(width: 8),
                    Text('My saved notes.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 10),

                // 📜 SCROLLABLE CONTAINER 1
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator.adaptive())
                      : savedNotesList.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Text('You have not saved any note yet.', style: TextStyle(color: Colors.grey)),
                  )
                      : ListView.builder(
                    itemCount: savedNotesList.length,
                    itemBuilder: (context, index) {
                      final note = savedNotesList[index];
                      return _buildNoteItemRow(note, index + 1);
                    },
                  ),
                ),

                const SizedBox(height: 20),
                const Divider(thickness: 1, color: Colors.grey),
                const SizedBox(height: 10),

                // SECTION 2 HEADER
                const Row(
                  children: [
                    Text('=', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    SizedBox(width: 8),
                    Text('My Events readings.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87, decoration: TextDecoration.underline)),
                  ],
                ),
                const SizedBox(height: 12),

                // 📜 SCROLLABLE CONTAINER 2
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator.adaptive())
                      : eventReadingsList.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Text('Notes generated through church events will display down here.', style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic)),
                  )
                      : ListView.builder(
                    itemCount: eventReadingsList.length,
                    itemBuilder: (context, index) {
                      final note = eventReadingsList[index];
                      return _buildEventItemRow(note, index + 1);
                    },
                  ),
                ),
                const SizedBox(height: 70),
              ],
            ),
          ),

          // 🚀 Add Note FAB
          Positioned(
            bottom: 20,
            right: 20,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NoteWorkspaceScreen(
                      noteId: null,
                      eventId: 1,
                      eventTitle: 'Personal Note',
                      isEditing: false,
                      initialTitle: '',
                      initialContent: '',
                    ),
                  ),
                ).then((value) => _loadNotesDataEngine());
              },
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text('Add Note', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                side: const BorderSide(color: Colors.blue, width: 1.2),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ROW COMPONENT GENERATOR: Personal Note Layout Style Variant
  Widget _buildNoteItemRow(Map<String, dynamic> note, int displayIndex) {
    final bool isPendingSync = note['syncStatus'] == 'PENDING';

    return InkWell(
      onTap: () => _navigateToWorkspace(note),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$displayIndex.', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                      children: [
                        const TextSpan(text: 'Title: '),
                        TextSpan(text: note['title'] ?? 'untitled', style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text(_formatPostgresDate(note['createdAt']), style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w500)),
                      if (isPendingSync) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.watch_later_outlined, size: 13, color: Colors.orange),
                      ]
                    ],
                  ),
                ],
              ),
            ),
            _buildActionMenu(note),
          ],
        ),
      ),
    );
  }

  // ROW COMPONENT GENERATOR: Event Sermon Layout Style Variant
  Widget _buildEventItemRow(Map<String, dynamic> note, int displayIndex) {
    final bool isPendingSync = note['syncStatus'] == 'PENDING';

    return InkWell(
      onTap: () => _navigateToWorkspace(note),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$displayIndex.', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(note['eventTitle'] ?? 'General Sermon Note', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0D47A1))),
                  const SizedBox(height: 2),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                      children: [
                        const TextSpan(text: 'Note: '),
                        TextSpan(text: note['title'] ?? 'untitled', style: const TextStyle(fontWeight: FontWeight.w500, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text(_formatPostgresDate(note['createdAt']), style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                      if (isPendingSync) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.watch_later_outlined, size: 12, color: Colors.orange),
                      ]
                    ],
                  ),
                ],
              ),
            ),
            _buildActionMenu(note),
          ],
        ),
      ),
    );
  }

  Widget _buildActionMenu(Map<String, dynamic> note) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.black54),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onSelected: (val) {
        if (val == 'share') _handleShareNote(note);
        if (val == 'edit') _navigateToWorkspace(note);
        if (val == 'delete') _showDeleteConfirmationSheet(note);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share, size: 18), SizedBox(width: 8), Text('Share')])),
        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
      ],
    );
  }
}