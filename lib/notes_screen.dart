import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:async';
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
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allNotesCache = []; // 🛡️ Master data backup copy
  List<Map<String, dynamic>> _displayNotes = [];  // 🎨 Active UI Display array
  bool _isLoading = true;
  bool _isOfflineMode = false;

  @override
  void initState() {
    super.initState();
    // 🧠 FAST PATH BOOTUP: Immediately pull from hardware to keep UI lightning responsive
    _loadLocalCacheOnly();

    // Wire up search controller query monitoring sequence
    _searchController.addListener(_executeNotesSearchFilter);
  }

  @override
  void dispose() {
    _searchController.removeListener(_executeNotesSearchFilter);
    _searchController.dispose();
    super.dispose();
  }

  // 🎯 THE FILTER ENGINE: Multi-field verification matching query string targets across arrays
  void _executeNotesSearchFilter() {
    final String query = _searchController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        // Reset display tracking copies to current global cache fallback state
        _displayNotes = List.from(_allNotesCache);
      } else {
        _displayNotes = _allNotesCache.where((note) {
          final String title = (note['title'] ?? '').toString().toLowerCase();
          final String content = (note['content'] ?? '').toString().toLowerCase();
          final String eventTitle = (note['eventTitle'] ?? '').toString().toLowerCase();

          return title.contains(query) || content.contains(query) || eventTitle.contains(query);
        }).toList();
      }
    });
  }

  /// 🏛️ LOCAL HARDWARE LOADER: Loads database instantly without touching the network
  Future<void> _loadLocalCacheOnly() async {
    final int activeId = SessionManager.currentUserId;
    if (!mounted) return;
    setState(() => _isLoading = true);

    final initialLocalNotes = await LocalDatabaseHelper.instance.getUserNotes(activeId);

    if (mounted) {
      setState(() {
        _allNotesCache = initialLocalNotes.map((note) {
          final Map<String, dynamic> modifiableMap = Map<String, dynamic>.from(note);
          final dynamic rawFav = note['isFavorite'];
          modifiableMap['isFavorite'] = (rawFav == 1 || rawFav == true) ? 1 : 0;
          return modifiableMap;
        }).toList();

        _isLoading = false; // Immediately lower loader flag
      });

      // Synchronize changes securely into current operational view lists
      _executeNotesSearchFilter();
      print('📊 FAST FEEDBACK: Rendered ${_allNotesCache.length} notes directly from SQLite disk storage.');
    }

    // Fire a silent background data update lookup without blocking UI interaction threads
    _silentBackgroundCloudRefresh();
  }

  /// 📡 SILENT SENTINEL SYNC: Handles network calls quietly in the background
  Future<void> _silentBackgroundCloudRefresh() async {
    final int activeId = SessionManager.currentUserId;
    final String dynamicFetchUrl = 'https://cathedral-backend-server-files-production.up.railway.app/api/notes/user/$activeId';

    try {
      final url = Uri.parse(dynamicFetchUrl);
      final response = await http.get(url).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        List<dynamic> networkNotes = jsonDecode(response.body);
        _isOfflineMode = false;

        if (networkNotes.isNotEmpty) {
          await LocalDatabaseHelper.instance.refreshLocalCache(networkNotes);
          final finalLocalNotes = await LocalDatabaseHelper.instance.getUserNotes(activeId);
          if (mounted) {
            setState(() {
              _allNotesCache = finalLocalNotes.map((note) {
                final Map<String, dynamic> modifiableMap = Map<String, dynamic>.from(note);
                final dynamic rawFav = note['isFavorite'];
                modifiableMap['isFavorite'] = (rawFav == 1 || rawFav == true) ? 1 : 0;
                return modifiableMap;
              }).toList();
              _isOfflineMode = false;
            });
            _executeNotesSearchFilter();
          }
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isOfflineMode = true);
      }
    }

    if (!_isOfflineMode) {
      _synchronizePendingOfflineNotes();
    }
  }

  /// 🔄 PULL DOWN ENGINE REFRACTOR: Executed when user pulls down the layout
  Future<void> _loadNotesDataEngine() async {
    final int activeId = SessionManager.currentUserId;
    print("🔍 PULL-TO-REFRESH ACTION: Processing live server refresh grid data...");
    final initialLocalNotes = await LocalDatabaseHelper.instance.getUserNotes(activeId);
    if (mounted && initialLocalNotes.isNotEmpty) {
      setState(() {
        _allNotesCache = initialLocalNotes.map((note) {
          final Map<String, dynamic> modifiableMap = Map<String, dynamic>.from(note);
          final dynamic rawFav = note['isFavorite'];
          modifiableMap['isFavorite'] = (rawFav == 1 || rawFav == true) ? 1 : 0;
          return modifiableMap;
        }).toList();
      });
      _executeNotesSearchFilter();
    }

    final String dynamicFetchUrl = 'https://cathedral-backend-server-files-production.up.railway.app/api/notes/user/$activeId';

    try {
      final response = await http.get(Uri.parse(dynamicFetchUrl)).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        List<dynamic> networkNotes = jsonDecode(response.body);
        _isOfflineMode = false;

        if (networkNotes.isNotEmpty) {
          await LocalDatabaseHelper.instance.refreshLocalCache(networkNotes);
          final finalLocalNotes = await LocalDatabaseHelper.instance.getUserNotes(activeId);

          if (mounted) {
            setState(() {
              _allNotesCache = finalLocalNotes.map((note) {
                final Map<String, dynamic> modifiableMap = Map<String, dynamic>.from(note);
                final dynamic rawFav = note['isFavorite'];
                modifiableMap['isFavorite'] = (rawFav == 1 || rawFav == true) ? 1 : 0;
                return modifiableMap;
              }).toList();
            });
            _executeNotesSearchFilter();
            print('✅ PULL TO REFRESH: Cloud data successfully merged into SQLite layer.');
          }
        }
      }
    } catch (e) {
      print('🚨 PULL TO REFRESH DROPPED: Reverting to local cache pipeline view. ($e)');
      if (mounted) {
        setState(() => _isOfflineMode = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not reach database server. Displaying cached data.')),
        );
      }
    }

    if (!_isOfflineMode) {
      await _synchronizePendingOfflineNotes();
    }
  }

  Future<void> _synchronizePendingOfflineNotes() async {
    final int activeId = SessionManager.currentUserId;
    final db = await LocalDatabaseHelper.instance.database;

    final List<Map<String, dynamic>> pendingDeletions = await db.query(
        'local_notes',
        where: 'syncStatus = ? AND userId = ?',
        whereArgs: ['DELETED', activeId]
    );

    for (var note in pendingDeletions) {
      final int targetId = note['id'];
      final String deleteUrl = 'https://cathedral-backend-server-files-production.up.railway.app/api/notes/delete/$targetId';

      try {
        final response = await http.delete(Uri.parse(deleteUrl)).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200 || response.statusCode == 404) {
          await LocalDatabaseHelper.instance.clearNoteFromHardware(targetId);
          print('✅ BACKGROUND SYNC PURGE: Verified Note ID $targetId removed.');
        }
      } catch (e) {
        print('🚨 BACKGROUND DELETION LOG STALL: Server unreachable.');
      }
    }
  }

  String _formatPostgresDate(dynamic rawDate) {
    if (rawDate == null) return 'Recent Note';
    final String rawDateString = rawDate.toString();
    if (rawDateString.isEmpty) return 'Recent Note';

    try {
      DateTime parsedDate = DateTime.parse(rawDateString);
      List<String> months = [
        'Jan', 'Feb', 'March', 'April', 'May', 'June',
        'July', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec'
      ];
      return '${parsedDate.day} ${months[parsedDate.month - 1]} ${parsedDate.year}';
    } catch (e) {
      return 'Recent Note';
    }
  }

  void _showDeleteConfirmationSheet(Map<String, dynamic> note, bool isDark, Color mainText) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                Text(
                  'Delete this note?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: mainText),
                ),
                const SizedBox(height: 8),
                Text(
                  'It will be permanently deleted from your device.',
                  style: TextStyle(fontSize: 14, color: isDark ? Colors.white60 : Colors.grey),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: isDark ? Colors.white38 : Colors.black87),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Cancel', style: TextStyle(color: mainText, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          final dynamic targetId = note['id'];
                          _executeFinalDestruction(targetId);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  Future<void> _executeFinalDestruction(dynamic noteId) async {
    if (noteId == null) return;
    final int targetId = int.parse(noteId.toString());

    setState(() {
      _allNotesCache.removeWhere((element) => element['id'].toString() == targetId.toString());
      _displayNotes.removeWhere((element) => element['id'].toString() == targetId.toString());
    });

    if (targetId < 0) {
      await LocalDatabaseHelper.instance.clearNoteFromHardware(targetId);
      return;
    }

    bool cloudDeleteSuccess = false;
    final String deleteUrl = 'https://cathedral-backend-server-files-production.up.railway.app/api/notes/delete/$targetId';

    try {
      final response = await http.delete(Uri.parse(deleteUrl)).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        cloudDeleteSuccess = true;
      }
    } catch (_) {}

    if (cloudDeleteSuccess) {
      await LocalDatabaseHelper.instance.clearNoteFromHardware(targetId);
    } else {
      await LocalDatabaseHelper.instance.queueOfflineDeletion(targetId);
    }
  }

  void _handleShareNote(Map<String, dynamic> note) {
    final String shareBody = 'Reflections from: ${note['eventTitle'] ?? 'Personal Reflections'}\n\n'
        'Title: ${note['title'] ?? 'Untitled'}\n'
        'Date: ${_formatPostgresDate(note['createdAt'] ?? note['dateCreated'] ?? note['date'])}\n\n'
        '${note['content'] ?? ''}';

    Share.share(shareBody, subject: note['title'] ?? 'Cathedral Service Insights');
  }

  Future<void> _toggleFavoriteNoteStatus(Map<String, dynamic> note) async {
    if (note['id'] == null) return;
    final int targetNoteId = int.parse(note['id'].toString());

    final bool currentStatus = note['isFavorite'] == 1 || note['isFavorite'] == true;
    final int updatedBitValue = currentStatus ? 0 : 1;

    setState(() {
      final cacheIndex = _allNotesCache.indexWhere((element) => element['id'].toString() == targetNoteId.toString());
      if (cacheIndex != -1) {
        _allNotesCache[cacheIndex]['isFavorite'] = updatedBitValue;
      }
      final displayIndex = _displayNotes.indexWhere((element) => element['id'].toString() == targetNoteId.toString());
      if (displayIndex != -1) {
        _displayNotes[displayIndex]['isFavorite'] = updatedBitValue;
      }
    });

    try {
      await LocalDatabaseHelper.instance.updateNoteFavoriteStatus(targetNoteId, updatedBitValue);
    } catch (_) {}

    if (!_isOfflineMode) {
      try {
        final bool targetStatusForServer = (updatedBitValue == 1);
        final String favUrl = 'https://cathedral-backend-server-files-production.up.railway.app/api/notes/$targetNoteId/favorite?status=$targetStatusForServer';
        await http.patch(Uri.parse(favUrl)).timeout(const Duration(seconds: 4));
      } catch (_) {}
    }
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
    ).then((value) => _loadLocalCacheOnly());
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color mainTextColor = isDark ? Colors.white : Colors.black87;
    final Color borderStrokeColor = isDark ? Colors.white30 : Colors.black54;
    final Color searchFieldBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color inlineDividerColor = isDark ? Colors.white12 : Colors.grey;

    final List<dynamic> savedNotesList = _displayNotes.where((note) {
      final String title = (note['eventTitle'] ?? '').toString();
      return title.isEmpty || title == 'Personal Note' || title == 'Cathedral Service' || title == 'General Sermon Note';
    }).toList();

    final List<dynamic> eventReadingsList = _displayNotes.where((note) {
      final String title = (note['eventTitle'] ?? '').toString();
      return title.isNotEmpty && title != 'Personal Note' && title != 'Cathedral Service' && title != 'General Sermon Note';
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: mainTextColor),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
          },
        ),
        title: Row(
          children: [
            Text('My Notes', style: TextStyle(color: mainTextColor, fontWeight: FontWeight.bold, fontSize: 22)),
            if (_isOfflineMode) ...[
              const SizedBox(width: 8),
              const Icon(Icons.cloud_off, color: Colors.redAccent, size: 18),
            ]
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotesDataEngine,
        color: Colors.blueAccent,
        child: Stack(
          children: [
            ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: searchFieldBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderStrokeColor, width: 1.2),
                  ),
                  child: TextField(
                    controller: _searchController, // 🔗 Bound the state search engine controller here!
                    style: TextStyle(color: mainTextColor),
                    decoration: InputDecoration(
                      hintText: 'Search for notes and readings',
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: isDark ? Colors.white60 : Colors.black54, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    const Text('=', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    const SizedBox(width: 8),
                    Text('My saved notes.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: mainTextColor)),
                  ],
                ),
                const SizedBox(height: 10),

                _isLoading
                    ? const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(child: CircularProgressIndicator.adaptive()),
                )
                    : savedNotesList.isEmpty
                    ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Text(
                      _searchController.text.isNotEmpty ? 'No matching personal notes found.' : 'You have not saved any note yet.',
                      style: const TextStyle(color: Colors.grey)),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: savedNotesList.length,
                  itemBuilder: (context, index) {
                    final note = savedNotesList[index];
                    final int masterIndex = _displayNotes.indexWhere((element) => element['id'].toString() == note['id'].toString());
                    return _buildNoteItemRow(_displayNotes[masterIndex], index + 1, mainTextColor, isDark);
                  },
                ),

                const SizedBox(height: 20),
                Divider(thickness: 1, color: inlineDividerColor),
                const SizedBox(height: 10),

                Row(
                  children: [
                    const Text('=', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    const SizedBox(width: 8),
                    Text(
                        'My Events readings.',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: mainTextColor, decoration: TextDecoration.underline, decorationColor: mainTextColor)
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _isLoading
                    ? const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(child: CircularProgressIndicator.adaptive()),
                )
                    : eventReadingsList.isEmpty
                    ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Text(
                      _searchController.text.isNotEmpty ? 'No matching event readings found.' : 'Notes generated through church events will display down here.',
                      style: const TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic)),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: eventReadingsList.length,
                  itemBuilder: (context, index) {
                    final note = eventReadingsList[index];
                    final int masterIndex = _displayNotes.indexWhere((element) => element['id'].toString() == note['id'].toString());
                    return _buildEventItemRow(_displayNotes[masterIndex], index + 1, mainTextColor, isDark);
                  },
                ),
                const SizedBox(height: 100),
              ],
            ),

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
                  ).then((value) => _loadLocalCacheOnly());
                },
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text('Add Note', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  backgroundColor: isDark ? Colors.blue[600] : const Color(0xFF0D47A1),
                  side: BorderSide(color: isDark ? Colors.blue.shade300 : Colors.blue, width: 1.2),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteItemRow(Map<String, dynamic> note, int displayIndex, Color mainText, bool isDark) {
    final bool isPendingSync = note['syncStatus'] == 'PENDING';
    final Color dateColor = isDark ? Colors.green.shade300 : Colors.green.shade700;

    return InkWell(
      onTap: () => _navigateToWorkspace(note),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$displayIndex.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: mainText)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 14, color: mainText),
                      children: [
                        const TextSpan(text: 'Title: '),
                        TextSpan(text: note['title'] ?? 'untitled', style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text(_formatPostgresDate(note['createdAt']), style: TextStyle(fontSize: 13, color: dateColor, fontWeight: FontWeight.w500)),
                      if (isPendingSync) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.watch_later_outlined, size: 13, color: Colors.orange),
                      ]
                    ],
                  ),
                ],
              ),
            ),
            _buildActionMenu(note, isDark, mainText),
          ],
        ),
      ),
    );
  }

  Widget _buildEventItemRow(Map<String, dynamic> note, int displayIndex, Color mainText, bool isDark) {
    final bool isPendingSync = note['syncStatus'] == 'PENDING';
    final Color eventTitleColor = isDark ? Colors.blue.shade300 : const Color(0xFF0D47A1);
    final Color subtitleColor = isDark ? Colors.white60 : Colors.grey.shade600;

    return InkWell(
      onTap: () => _navigateToWorkspace(note),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$displayIndex.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: mainText)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(note['eventTitle'] ?? 'General Sermon Note', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: eventTitleColor)),
                  const SizedBox(height: 2),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 13, color: mainText),
                      children: [
                        const TextSpan(text: 'Note: '),
                        TextSpan(text: note['title'] ?? 'untitled', style: const TextStyle(fontWeight: FontWeight.w500, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text(_formatPostgresDate(note['createdAt']), style: TextStyle(fontSize: 12, color: subtitleColor, fontWeight: FontWeight.w500)),
                      if (isPendingSync) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.watch_later_outlined, size: 12, color: Colors.orange),
                      ]
                    ],
                  ),
                ],
              ),
            ),
            _buildActionMenu(note, isDark, mainText),
          ],
        ),
      ),
    );
  }

  Widget _buildActionMenu(Map<String, dynamic> note, bool isDark, Color mainText) {
    final bool isFav = note['isFavorite'] == 1 || note['isFavorite'] == true;

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: isDark ? Colors.white60 : Colors.black54),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      onSelected: (val) {
        if (val == 'share') _handleShareNote(note);
        if (val == 'edit') _navigateToWorkspace(note);
        if (val == 'favorite') _toggleFavoriteNoteStatus(note);
        if (val == 'delete') _showDeleteConfirmationSheet(note, isDark, mainText);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'favorite',
          child: Row(
            children: [
              Icon(
                isFav ? Icons.favorite : Icons.favorite_border_rounded,
                size: 18,
                color: isFav ? Colors.redAccent : mainText,
              ),
              const SizedBox(width: 8),
              Text(
                isFav ? 'Unfavorite' : 'Favorite',
                style: TextStyle(color: mainText, fontWeight: isFav ? FontWeight.bold : FontWeight.normal),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'share',
          child: Row(children: [
            Icon(Icons.share, size: 18, color: mainText),
            const SizedBox(width: 8),
            Text('Share', style: TextStyle(color: mainText))
          ]),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(children: [
            Icon(Icons.edit, size: 18, color: mainText),
            const SizedBox(width: 8),
            Text('Edit', style: TextStyle(color: mainText))
          ]),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            Icon(Icons.delete, color: Colors.redAccent, size: 18),
            const SizedBox(width: 8),
            Text('Delete', style: TextStyle(color: Colors.redAccent))
          ]),
        ),
      ],
    );
  }
}