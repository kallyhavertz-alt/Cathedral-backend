import 'package:flutter/material.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  // 📚 Section 1 Data: Saved Notes matching your exact blueprint text
  final List<Map<String, String>> _savedNotes = [
    {
      'number': '1.',
      'type': 'Psalm Sunday notes',
      'title': 'Hosanna Muthamaki',
    },
    {
      'number': '2.',
      'type': 'Holy Communion note',
      'title': 'Evil backfires!',
    },
  ];

  // 🗓️ Section 2 Data: Event Readings matching your exact calendar logs
  final List<Map<String, String>> _eventReadings = [
    {
      'number': '1.',
      'title': 'Psalm Sunday reading',
      'date': '17th March 2026',
    },
    {
      'number': '2.',
      'title': 'Holy Communion reading',
      'date': '24th March 2026',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Top Custom Navigation App Bar row matching your sketch top-line
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            // Optional back navigation logic
          },
        ),
        title: const Text(
          'My Notes',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔍 SKETCH COMPONENT: Custom Styled Search Bar Field
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
                const SizedBox(height: 24),

                // ==========================================
                // SECTION 1: MY SAVED NOTES
                // ==========================================
                const Row(
                  children: [
                    Text('=', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    SizedBox(width: 8),
                    Text(
                      'My saved notes.',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Generating the numbered notes list
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _savedNotes.length,
                  itemBuilder: (context, index) {
                    final note = _savedNotes[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note['number']!,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  note['type']!,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0D47A1)),
                                ),
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                                    children: [
                                      const TextSpan(text: 'Title: '),
                                      TextSpan(
                                        text: note['title']!,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // ==========================================
                // SECTION 2: MY EVENTS READINGS
                // ==========================================
                const Row(
                  children: [
                    Text('=', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    SizedBox(width: 8),
                    Text(
                      'My Events readings.',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87, decoration: TextDecoration.underline),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Generating the numbered events list
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _eventReadings.length,
                  itemBuilder: (context, index) {
                    final reading = _eventReadings[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reading['number']!,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reading['title']!,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  reading['date']!,
                                  style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 80), // Creates safety spacing so content doesn't hide under the button
              ],
            ),
          ),

          // 🚀 SKETCH COMPONENT: Bottom Right Rectangular Custom "+ Add Note" Action Button
          Positioned(
            bottom: 16,
            right: 16,
            child: OutlinedButton.icon(
              onPressed: () {
                // Trigger dynamic dialog block or new writing intent lane here later
              },
              icon: const Icon(Icons.add, size: 16, color: Colors.redAccent),
              label: const Text(
                'Add Note',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                side: const BorderSide(color: Colors.yellow, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}