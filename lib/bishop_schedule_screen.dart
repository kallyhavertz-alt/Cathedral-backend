import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'event_details_screen.dart';

class BishopScheduleScreen extends StatefulWidget {
  const BishopScheduleScreen({Key? key}) : super(key: key);

  @override
  State<BishopScheduleScreen> createState() => _BishopScheduleScreenState();
}


class _BishopScheduleScreenState extends State<BishopScheduleScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isNewestFirst = true;

  List<dynamic> _liveSchedules = [];
  bool _isLoading = true;
  String _errorMessage = "";

  final String baseUrl = 'http://192.168.100.33:8080/api/v1';

  @override
  void initState() {
    super.initState();
    _fetchBishopSchedule();
  }

  Future<void> _fetchBishopSchedule() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final Uri url = Uri.parse('$baseUrl/posts?type=BISHOP_SPECIAL');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _liveSchedules = jsonDecode(response.body);
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
    List<dynamic> filtered = _liveSchedules.where((item) {
      final text = "${item['title']} ${item['content']}".toLowerCase();
      return text.contains(_searchQuery.toLowerCase());
    }).toList();

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
          "Bishop Schedule",
          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search schedule items...',
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

          // LIST VIEW CONTAINER
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
                : RefreshIndicator(
              onRefresh: _fetchBishopSchedule,
              child: filtered.isEmpty
                  ? const Center(child: Text('No schedule updates listed.'))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                itemCount: filtered.length,
                itemBuilder: (context, index) => _buildScheduleCardLayout(filtered[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 🛠️ NEW UPDATED CARD LAYOUT ====================
  Widget _buildScheduleCardLayout(Map<String, dynamic> item) {
    // Safely pull sender/poster data from payload mapping fields (handles maps or nested structures gracefully)
    final String postedBy = item['senderName'] ?? item['postedBy'] ?? 'Cathedral Admin';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      height: 165, // Increased slightly to comfortably hold "Posted by" footprint metadata
      child: Stack(
        children: [
          // 🖼️ 1. BACKGROUND GRADIENT IMAGE (Faded overlay so absolute left alignment text stands out)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/icons/bishop.png',
                fit: BoxFit.cover,
                alignment: Alignment.centerLeft,
                errorBuilder: (c, e, s) => Container(color: const Color(0xFF1A1A1A)),
              ),
            ),
          ),

          // 🎨 2. BALANCED DARK TINT OVERLAY (Ensures text on absolute left reads perfectly)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.black.withValues(alpha: 0.70),
                    Colors.black.withValues(alpha: 0.90),
                  ],
                ),
              ),
            ),
          ),

          // 📝 3. ABSOLUTE LEFT ALIGNED LAYOUT + GESTURE ROUTING INTERACTION
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Text column starts completely from absolute left now!
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
                          color: Colors.amberAccent,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['content'] ?? '',
                        maxLines: 2, // Dropped to 2 to make clean visual room for poster name
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 👤 POSTED BY METADATA FOOTPRINT
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 12, color: Colors.redAccent),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'By: $postedBy',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),

                      // TIME & DATE ROW
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 11, color: Colors.white60),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${item['formattedDate'] ?? 'Today'} | 🕒 ${item['formattedTime'] ?? 'Now'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: Colors.white60, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // 🎯 INTERACTIVE ACK EMBLEM SYMBOL GESTURE DETECTOR
                GestureDetector(
                  onTap: () {

                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EventDetailsScreen(eventItem: item, eventData: {},)),
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
                        errorBuilder: (c, e, s) => const Icon(Icons.church, color: Colors.redAccent, size: 28),
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