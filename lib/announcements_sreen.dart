import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'event_details_screen.dart';
import 'bb_text_formatter.dart';
import 'file_download_service.dart';

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

  /// Helper logic to isolate and extract the first name from the sender ID string safely
  String _getSenderFirstName(dynamic senderId) {
    if (senderId == null || senderId.toString().trim().isEmpty) {
      return "Staff";
    }

    String cleanId = senderId.toString().trim();

    // If it's an email string, split before the domain boundary
    if (cleanId.contains('@')) {
      cleanId = cleanId.split('@')[0];
    }

    // Split by spaces or underscores to grab the first structural name segment
    List<String> parts = cleanId.split(RegExp(r'[\s_.]'));
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      // Capitalize the first letter for a clean appearance
      return parts[0][0].toUpperCase() + parts[0].substring(1).toLowerCase();
    }

    return "Staff";
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
    final String uploaderName = _getSenderFirstName(item['senderName'] ?? item['fullName'] ?? 'Staff Member');

    // 🔍 1. Identify if a valid server image url was fetched
    String? fileUrl = item['fileUrl'];
    String isFileType = item['isFileType'] ?? 'TEXT';
    bool hasLiveImage = (isFileType == "IMAGE" && fileUrl != null && fileUrl.isNotEmpty);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      height: 180,
      child: Stack(
        children: [
          // 🖼️ DYNAMIC LIVE IMAGE / FALLBACK CANVAS BACKGROUND
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: hasLiveImage
                  ? Image.network(
                'http://192.168.100.33:8080$fileUrl', // Your local Spring Boot server asset port
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  color: Colors.blueGrey,
                  child: const Icon(Icons.broken_image_outlined, color: Colors.white24, size: 40),
                ),
              )
                  : Image.asset(
                'assets/icons/announce.png',
                fit: BoxFit.cover,
                alignment: Alignment.centerLeft,
                errorBuilder: (c, e, s) => Container(color: const Color(0xFF1A1A1A)),
              ),
            ),
          ),

          // 🏁 CONTRAST GRADIENT OVERLAY LAYER
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    // If it's a live upload image, we slightly deepen the gradient value for ultimate text legibility
                    Colors.black.withValues(alpha: hasLiveImage ? 0.9 : 0.85)
                  ],
                ),
              ),
            ),
          ),

          // 📝 FOREGROUND CONTENT CONTAINER
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        item['title'].toString().toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      BBText(
                        text: item['content'] ?? '',
                        charLimit: 40,
                        color: Colors.white,
                        fontSize: 13,
                      ),
                      const SizedBox(height: 8),

                      // POSTED BY:
                      Row(
                        children: [
                          const Icon(Icons.person_pin_circle_rounded, size: 14, color: Colors.amberAccent),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Posted by: $uploaderName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: Colors.amberAccent, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),

                      // timestamp
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 11, color: Colors.blueGrey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${item['formattedDate'] ?? 'Today'} | 🕒 ${item['formattedTime'] ?? 'Now'}',
                              style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w500, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 56),
              ],
            ),
          ),

          // Action navigation symbol
          Positioned(
            bottom: 16,
            right: 16,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EventDetailsScreen(
                      eventData: item,
                    ),
                  ),
                );
              },
              child: Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white70, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3))
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/icim/cathsign.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Icon(Icons.notifications_active_outlined, color: Colors.redAccent),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}