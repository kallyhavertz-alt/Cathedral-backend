import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:untitled/note_work_space_screen.dart';

class EventDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> eventItem;

  const EventDetailsScreen({Key? key, required this.eventItem}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Stringify fields safely to prevent type deadlocks
    final int eventId = eventItem['id'] is int ? eventItem['id'] : int.tryParse(eventItem['id'].toString()) ?? 0;
    final String eventTitle = (eventItem['eventTitle'] ?? 'Cathedral Event').toString();
    final String description = (eventItem['description'] ?? 'Join us for our specialized service.').toString();
    final String scheduledAt = (eventItem['eventDate'] ?? 'Date Pending').toString();

    // Fallback constants so you can see your beautiful layout work before altering PostgreSQL text blocks!
    final String featuredReading = eventItem['featuredEventReading'] != null
        ? eventItem['featuredEventReading'].toString()
        : 'Romans 10:13';

    final String readingText = eventItem['eventReadingText'] != null
        ? eventItem['eventReadingText'].toString()
        : 'For whoever calls on the name of the Lord shall be saved.';

    return Scaffold(
      backgroundColor: Colors.white, // Pure white canvas background from sketch guidance
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Event Detail View',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ==========================================
            // 🔳 THE HAND-DRAWN DYNAMIC HEADER CARD BOX
            // ==========================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black45, width: 1.2), // Prominent structural outline border
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Header Title Text
                  Text(
                    eventTitle.toUpperCase(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),

                  // Full Description text block
                  Text(
                    description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  // Scheduled time stamp element lines
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 8, color: Colors.redAccent), // Small bullet circle marker from sketch
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Scheduled at:\n$scheduledAt',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: Colors.black12),

                  // 🛠️ INNER ACTION ROW: Nesting the "+" Workspace Link & Share triggers inside card bottom!
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Interactive Note creation link lane
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
                            const Icon(Icons.add_box, color: Colors.black87, size: 28), // The explicit hand-drawn "+" add box icon
                            const SizedBox(width: 8),
                            Text(
                              'Add Note for event',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                            ),
                          ],
                        ),
                      ),

                      // Secondary Share Icon matching your drawn network nodes anchor point symbol
                      IconButton(
                        icon: const Icon(Icons.share_outlined, color: Colors.black87, size: 22),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sharing event details option coming soon...')),
                          );
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.account_circle)
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ==========================================
            // 📑 OUTSIDE THE CARD: SCRIPTURE & COPY BLUEPRINTS
            // ==========================================
            const Row(
              children: [
                Text('≡', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                SizedBox(width: 8),
                Text(
                  'Featured Event reading',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Scripture Marker (e.g. Romans 10:13)
            Text(
              featuredReading,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const Icon(Icons.copy, size: 12, color: Colors.blue,),

            // Main Core Scripture Quote Verse lines
            Text(
              readingText,
              style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: Colors.black87, height: 1.4),
            ),
            const SizedBox(height: 14),

            // 📋 THE DRAWN BUTTON: "Copy reading" item wrapper text box structure
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.black87, width: 1.5), // Matches custom handwritten box highlight lines
                ),
                child: const Text(
                  'Copy reading',
                  style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 10),
            Text(
              'You can copy the reading to save to your notes!',
              style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}