import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'event_details_screen.dart';

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
    // Safely grab the staff user metadata identity string
    final String postedBy = item['senderName'] ?? item['postedBy'] ?? 'Cathedral Admin';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      height: 180,
      child: Stack(
        children: [
          //  DYNAMIC PICSUM  BACKGROUND
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                'https://picsum.photos/seed/${item['id']}/600/300',
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(color: Colors.blueGrey),
              ),
            ),
          ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.80),
                    Colors.black.withValues(alpha: 0.40),
                    Colors.black.withValues(alpha: 0.85), // Fading black from right side
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

                    Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end, // Anchors  smoothly to the base
                    children: [
                      Text(
                        item['title'].toString().toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.cyanAccent, // Cyan accent pops cleanly on dark vignettes
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['content'] ?? '',
                       // BBTextFormatter.parseToRichText(context, item['content'] ?? '') as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.2),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 12, color: Colors.cyanAccent),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'By: $postedBy',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),

                      //TIMESTAMP
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
                const SizedBox(width: 56),
              ],
            ),
          ),

          //ACK LOGO
          Positioned(
            bottom: 16,
            right: 16,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EventDetailsScreen(
                      eventData: item,
                      eventItem: const {},
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
class BBTextFormatter {
  static Widget parseToRichText(BuildContext context, String input, {double fontSize = 13.0, double height = 1.3}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color defaultColor = isDark ? Colors.white70 : Colors.black87;
    final Color blueColor = isDark ? Colors.lightBlueAccent : const Color(0xFF0D47A1);
    final Color redColor = isDark ? Colors.redAccent : const Color(0xFFC62828);
    final Color greenColor = isDark ? Colors.greenAccent : const Color(0xFF2E7D32);

    final List<TextSpan> spans = [];
    RegExp regExp = RegExp(r'\[([brg])\](.*?)\[\/\1\]|([^\[]+)', dotAll: true);
    // final RegExp regExp = RegExp(r'<(b)>(.*?)</\1>|([^<]+)', dotAll: true);
    final Iterable<Match> matches = regExp.allMatches(input);

    for (final Match match in matches) {
      if (match.group(3) != null) {
        spans.add(TextSpan(text: match.group(3), style: TextStyle(color: defaultColor, fontSize: fontSize, height: height)));
      } else {
        final String? tag = match.group(1);
        final String textContent = match.group(2) ?? '';
        Color targetColor = defaultColor;
        FontWeight weight = FontWeight.normal;

        if (tag == 'b') { targetColor = blueColor; weight = FontWeight.bold; }
        else if (tag == 'r') { targetColor = redColor; weight = FontWeight.bold; }
        else if (tag == 'g') { targetColor = greenColor; weight = FontWeight.bold; }

        spans.add(TextSpan(text: textContent, style: TextStyle(color: targetColor, fontWeight: weight, fontSize: fontSize, height: height)));
      }
    }
    return RichText(text: TextSpan(children: spans));
  }
}