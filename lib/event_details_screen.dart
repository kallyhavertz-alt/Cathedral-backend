import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:untitled/note_work_space_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:untitled/local_database_helper.dart';
import 'package:untitled/session_manager.dart';

class EventDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> eventItem;

  const EventDetailsScreen({Key? key, required this.eventItem, required Map<String, dynamic> eventData}) : super(key: key);

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool _isLiked = false;
  late int eventId;
  late String eventTitle;
  late String description;
  late String scheduledAt;
  late String featuredReading;
  late String readingText;

  @override
  void initState() {
    super.initState();
    eventId = widget.eventItem['id'] is int ? widget.eventItem['id'] : int.tryParse(widget.eventItem['id'].toString()) ?? 0;
    eventTitle = (widget.eventItem['eventTitle'] ?? 'Cathedral Event').toString();
    description = (widget.eventItem['description'] ?? 'Join us for our specialized service.').toString();
    scheduledAt = (widget.eventItem['eventDate'] ?? 'Date Pending').toString();

    featuredReading = widget.eventItem['featuredEventReading'] != null
        ? widget.eventItem['featuredEventReading'].toString()
        : 'Romans 10:13';

    readingText = widget.eventItem['eventReadingText'] != null
        ? widget.eventItem['eventReadingText'].toString()
        : 'For whoever calls on the name of the Lord shall be saved.';

    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final int activeUserId = SessionManager.currentUserId;
      final db = await LocalDatabaseHelper.instance.database;

      // Look inside the existing local_notes table for an event matching this ID marked as a favorite
      final List<Map<String, dynamic>> match = await db.query(
        'local_notes',
        where: 'userId = ? AND eventId = ? AND isFavorite = 1',
        whereArgs: [activeUserId, eventId],
      );

      if (mounted && match.isNotEmpty) {
        setState(() {
          _isLiked = true;
        });
      }
    } catch (e) {
      print('🚨 Error reading initial favorite token: $e');
    }
  }
  Future<void> _toggleFavorite() async {
    try {
      final int activeUserId = SessionManager.currentUserId;
      final db = await LocalDatabaseHelper.instance.database;

      if (_isLiked) {
        // Unfavoriting: Remove the favorite flag or delete the row if it's just a placeholder event note
        await db.update(
          'local_notes',
          {'isFavorite': 0},
          where: 'userId = ? AND eventId = ?',
          whereArgs: [activeUserId, eventId],
        );
        setState(() {
          _isLiked = false;
        });

        // 💬 ADDED: Floating removal message
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('💔 Removed "$eventTitle" from favorites.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.grey[900],
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Favoriting: Check if a record already exists
        final List<Map<String, dynamic>> existing = await db.query(
          'local_notes',
          where: 'userId = ? AND eventId = ?',
          whereArgs: [activeUserId, eventId],
        );

        if (existing.isNotEmpty) {
          await db.update(
            'local_notes',
            {'isFavorite': 1},
            where: 'userId = ? AND eventId = ?',
            whereArgs: [activeUserId, eventId],
          );
        } else {
          // If no note exists for this event yet, insert a placeholder record marked as favorite
          await db.insert('local_notes', {
            'id': DateTime.now().millisecondsSinceEpoch * -1, // Unique temporary local ID
            'userId': activeUserId,
            'eventId': eventId,
            'eventTitle': eventTitle,
            'title': '$eventTitle (Favorite)',
            'content': description,
            'createdAt': DateTime.now().toIso8601String(),
            'syncStatus': 'PENDING',
            'isFavorite': 1,
          });
        }

        setState(() {
          _isLiked = true;
        });

        // 💬 ADDED: Floating success message
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.favorite, color: Colors.redAccent, size: 20),
                  SizedBox(width: 10),
                  Text('Favourited! add a note to this event to save in your favourites', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.lightGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('🚨 Failed to execute database favorite transaction: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    // 🎨 DYNAMIC THEME DETECTOR CAPTURES
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // 🎨 Dynamic Palette Mapping
    final Color mainTextColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white70 : Colors.grey[800]!;
    final Color traceTextColor = isDark ? Colors.white60 : Colors.black54;
    final Color borderStrokeColor = isDark ? Colors.white38 : Colors.black45;
    final Color structuralIconColor = isDark ? Colors.white38 : Colors.black87;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: structuralIconColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Event Detail View',
          style: TextStyle(color: mainTextColor, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white, // Elevated card surface color
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderStrokeColor, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eventTitle.toUpperCase(),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(fontSize: 14, color: subTextColor, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 8, color: Colors.redAccent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Scheduled at:\n$scheduledAt',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: Colors.black12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NoteWorkspaceScreen(
                                noteId: null,
                                eventId: eventId,
                                eventTitle: eventTitle,
                                isEditing: false,
                                initialTitle: '$eventTitle Reflection',
                                initialContent: 'Verse context: "$readingText"\n\n',
                              ),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Icon(Icons.add_box, color: structuralIconColor, size: 28),
                            const SizedBox(width: 8),
                            Text(
                              'Add Note for event',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: subTextColor),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _isLiked ? Icons.favorite : Icons.favorite_border_rounded,
                              color: _isLiked ? Colors.redAccent : structuralIconColor,
                              size: 24,
                            ),
                            onPressed: _toggleFavorite,

                          ),
                         /* ScaffoldMessenger.of(context).showSnackBar(
                              snackBar(
                                Content(
                                  Text("LIKED! please add a note to appear in favourites"),
                                  behaviour: SnackBarBehavior.floating,
                                )
                              )
                          )*/
                          const SizedBox(width: 4),
                          IconButton(
                            icon: Icon(Icons.share_outlined, color: structuralIconColor, size: 22),
                            onPressed: () {
                              final String shareMessage =
                                  'ACK St. James Cathedral Event Update ⛪\n\n'
                                  '${eventTitle.toUpperCase()}\n'
                                  '$description\n\n'
                                  '️ Scheduled at: $scheduledAt\n\n'
                                  ' Featured Reading: $featuredReading\n'
                                  '_"$readingText"_\n\n'
                                  'Shared via Cathedral App.';

                              Share.share(shareMessage, subject: 'ACK Cathedral Event: $eventTitle');
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // OUTSIDE THE CARD

            Row(
              children: [
                const Text('≡', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                const SizedBox(width: 8),
                Text(
                  'Featured Event reading',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              featuredReading,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: mainTextColor),
            ),
            const SizedBox(height: 4),
            Text(
              readingText,
              style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: mainTextColor, height: 1.4),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: '$featuredReading\n"$readingText"'));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied "$featuredReading" text context to notebook!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: structuralIconColor, width: 1.5),
                ),
                child: Text(
                  'Copy reading',
                  style: TextStyle(color: mainTextColor, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'You can copy the reading to save to your notes!',
              style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}