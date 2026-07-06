import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'event_details_screen.dart';
import 'bb_text_formatter.dart';
import 'file_download_service.dart';

class OtherMinistriesPage extends StatefulWidget {
  const OtherMinistriesPage({Key? key}) : super(key: key);

  @override
  State<OtherMinistriesPage> createState() => _OtherMinistriesPageState();
}

class _OtherMinistriesPageState extends State<OtherMinistriesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isNewestFirst = true;

  // 📡 Network Database Connection States
  List<dynamic> _liveMinistries = [];
  bool _isLoading = true;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchOtherMinistries();
  }

  // 📡 Fetch Data from Render Endpoint
  Future<void> _fetchOtherMinistries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final Uri url = Uri.parse('http://192.168.100.33:8080/api/v1/posts?type=OTHER_MINISTRIES');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          _liveMinistries = jsonDecode(response.body);
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
        _errorMessage = "Connection dropped. Make sure your Render instance is active.";
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
    // 🔍 1. Filter by Search Query matching incoming backend keys
    List<dynamic> filtered = _liveMinistries.where((item) {
      final text = "${item['title']} ${item['content']}".toLowerCase();
      return text.contains(_searchQuery.toLowerCase());
    }).toList();

    // 🔄 2. Apply Chronological Sorting Rules
    filtered.sort((a, b) => _isNewestFirst
        ? b['id'].compareTo(a['id'])
        : a['id'].compareTo(b['id']));

    return Column(
      children: [
        // 🔍 SEARCH BAR
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search ministries...',
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),

        // 🏷️ SORT ORDER ROW
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isNewestFirst ? 'Showing: newest first' : 'Showing: oldest first',
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

        // 🔄 RENDERING PIPELINE FOR LIVE LIST
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
              : RefreshIndicator(
            onRefresh: _fetchOtherMinistries,
            child: filtered.isEmpty
                ? const Center(child: Text('No ministries found.'))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              itemCount: filtered.length,
              itemBuilder: (context, index) => _buildPicsumItemCard(filtered[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPicsumItemCard(Map<String, dynamic> item) {
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
                  : Image.network(
                // Fallback to Picsum seed only if it's a legacy TEXT post type with no image upload
                'https://picsum.photos/seed/${item['id']}/600/300',
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(color: Colors.blueGrey),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  item['title'].toString().toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                BBText(
                  text: item['content'] ?? '',
                  charLimit: 40,
                  color: Colors.white70,
                  fontSize: 13,
                ),
                const SizedBox(height: 8),

                // POSTED BY:
                Row(
                  children: [
                    const Icon(Icons.person_pin_circle_rounded, size: 14, color: Colors.cyanAccent),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Posted by: $uploaderName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),

                // timestamp
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 11, color: Colors.white60),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${item['formattedDate']} | 🕒 ${item['formattedTime']}',
                        style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.w500, fontSize: 11),
                      ),
                    ),
                  ],
                ),
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
                    errorBuilder: (c, e, s) => const Icon(Icons.church, color: Colors.cyanAccent),
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
