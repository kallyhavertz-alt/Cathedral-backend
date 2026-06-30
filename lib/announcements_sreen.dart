import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'event_details_screen.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({Key? key}) : super(key: key);

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isNewestFirst = true;

  // 📡 Network Database States
  List<dynamic> _liveAnnouncements = [];
  bool _isLoading = true;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final Uri url = Uri.parse('http://192.168.100.33:8080/api/v1/posts?type=ANNOUNCEMENT');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _liveAnnouncements = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Server error code: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Connection dropped.";
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🔍 1. Filter by Search Query matching text fields dynamically
    List<dynamic> filtered = _liveAnnouncements.where((item) {
      final text = "${item['title']} ${item['content']}".toLowerCase();
      return text.contains(_searchQuery.toLowerCase());
    }).toList();

    // 🔄 2. Apply Chronological Sorting Rules (Newest / Oldest first)
    filtered.sort((a, b) => _isNewestFirst
        ? b['id'].compareTo(a['id'])
        : a['id'].compareTo(b['id']));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.red),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Announcements',
          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 🔍 SEARCH BAR (Matches your sketch precisely)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search for ann...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // 🏷️ SORT ORDER ROW
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isNewestFirst ? 'showing: newest' : 'showing: oldest',
                  style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                InkWell(
                  onTap: () => setState(() => _isNewestFirst = !_isNewestFirst),
                  child: Row(
                    children: [
                      const Text('Sort order ', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                      Icon(_isNewestFirst ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, size: 14, color: Colors.redAccent),
                    ],
                  ),
                )
              ],
            ),
          ),

          // 🔄 MANUAL REFRESH VIEWABLE CONTAINER
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
                : RefreshIndicator(
              onRefresh: _fetchAnnouncements,
              child: filtered.isEmpty
                  ? const Center(child: Text('No announcements found.'))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                itemCount: filtered.length,
                itemBuilder: (context, index) => _buildNoticeCardLayout(filtered[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeCardLayout(Map<String, dynamic> item) {
    final String postedBy = item['senderName'] ?? item['postedBy'] ?? 'Cathedral Admin';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      height: 165,
      child: Stack(
        children: [
          //  BACKGROUND IMAGE
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/icons/announce.png',
                fit: BoxFit.cover,
                alignment: Alignment.centerLeft,
                errorBuilder: (c, e, s) => Container(color: const Color(0xFF1A1A1A)),
              ),
            ),
          ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.black.withValues(alpha: 0.75),
                    Colors.black.withValues(alpha: 0.90),
                  ],
                ),
              ),
            ),
          ),

          // 📝 3. CARD CONTENTS (Text absolute left aligned + ACK logo pinned far right)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Column starts cleanly from absolute left now!
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item['title'].toString().toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.redAccent, // Red accent pops sharply on the dark background
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['content'] ?? '',
                        maxLines: 2, // Dropped to 2 lines to allocate perfect vertical space for sender identity
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.3,
                          color: Colors.white70,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // 👤 POSTED BY METADATA FOOTPRINT
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 12, color: Colors.amberAccent),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'By: $postedBy',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: Colors.amberAccent, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),

                      // 🕒 TIME & DATE METADATA FOOTPRINT
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 11, color: Colors.blueGrey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Sent: ${item['formattedDate'] ?? 'Today'} | 🕒 ${item['formattedTime'] ?? 'Now'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),


                GestureDetector(
                  onTap: () {

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EventDetailsScreen( eventItem: {}, eventData: {},)),
                  );

                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5), width: 1),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/icim/cathsign.jpg',
                        width: 42,
                        height: 42,
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) => const Icon(Icons.notifications_active_outlined, color: Colors.redAccent, size: 26),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}