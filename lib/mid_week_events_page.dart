import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'event_details_screen.dart';

class MidWeekEventsPage extends StatefulWidget {
  const MidWeekEventsPage({Key? key}) : super(key: key);

  @override
  State<MidWeekEventsPage> createState() => _MidWeekEventsPageState();
}

class _MidWeekEventsPageState extends State<MidWeekEventsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isNewestFirst = true;

  String _selectedCategory = 'All events';
  final List<String> _categories = [
    'All events',
    'Daily prayers',
    'Wednesday holy communion',
    'Friday Hymnos',
    'Others'
  ];

  // 📡 Network Database Connection States
  List<dynamic> _liveEvents = [];
  bool _isLoading = true;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchMidWeekEvents();
  }

  Future<void> _fetchMidWeekEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final Uri url = Uri.parse('http://192.168.100.33:8080/api/v1/posts?type=MIDWEEK_EVENT');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> decodedData = jsonDecode(response.body);
        print("📡 RAW BACKEND PAYLOAD: ${response.body}");
        if (decodedData.isNotEmpty) {
          print("🔍 SAMPLE FIRST ITEM KEYS: ${decodedData.first.keys.toList()}");
          print("🏷️ SAMPLE FIRST ITEM CATEGORY VALUE: '${decodedData.first['midweekCategory']}'");
        }
        setState(() {
          _liveEvents = jsonDecode(response.body);
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
        _errorMessage = "Connection dropped";
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatCategoryLabel(String? rawCategory) {
    if (rawCategory == null || rawCategory.toLowerCase() == 'null') {
      return 'Special Event';
    }

    switch (rawCategory.toLowerCase()) {
      case 'daily_prayers':
      case 'daily prayers':
        return 'Daily Prayers';
      case 'wednesday_communion':
      case 'wednesday_holy_communion':
      case 'wednesday holy communion':
        return 'Wednesday Holy Communion';
      case 'friday_hymnos':
      case 'friday hymnos':
        return 'Friday Hymnos';
      case 'others':
      case 'none':
        return 'Others';
      default:

        return rawCategory[0].toUpperCase() + rawCategory.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mainTextColor = isDark ? Colors.white : Colors.black87;

    // 🔍 1. Filter by Search Query matching incoming backend keys
    List<dynamic> filtered = _liveEvents.where((item) {
      bool matchesCategory = true;
      print("Comparing selected filter: '$_selectedCategory' against raw database value: '${item['MidweekCategory']}'");

      if (_selectedCategory != 'All events') {
        // Checking both common key variations for robustness
        String rawCategory = (item['midweekCategory'] ?? item['MidweekCategory'] ?? 'NONE').toString().toUpperCase();



        if (_selectedCategory == 'Daily prayers') {
          matchesCategory = (rawCategory == 'DAILY_PRAYERS' || rawCategory == 'DAILY PRAYERS');
        } else if (_selectedCategory == 'wednesday holy communion') {
          matchesCategory = (rawCategory == 'WEDNESDAY_COMMUNION' || 
                             rawCategory == 'wednesday holy communion' ||
                             rawCategory == 'wednesday');
        } else if (_selectedCategory == 'Friday Hymnos') {
          matchesCategory = (rawCategory == 'FRIDAY_HYMNOS' || rawCategory == 'FRIDAY HYMNOS');
        } else if (_selectedCategory == 'Others') {
          matchesCategory = (rawCategory == 'NONE' || rawCategory == 'OTHERS');
        }
      }
      final text = "${item['title']} ${item['content']}".toLowerCase();
      return matchesCategory && text.contains(_searchQuery.toLowerCase());
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
            style: TextStyle(color: mainTextColor),
            decoration: InputDecoration(
              hintText: 'Search mid-week events...',
              hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
              prefixIcon: Icon(Icons.search, size: 20, color: isDark ? Colors.white70 : Colors.grey),
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

        // 🏷️ CATEGORY DROPDOWN
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedCategory,
                dropdownColor: isDark ? Colors.grey[900] : Colors.white,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.redAccent),
                items: _categories.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: TextStyle(fontSize: 14, color: mainTextColor)),
                  );
                }).toList(),
                onChanged: (newValue) => setState(() => _selectedCategory = newValue!),
              ),
            ),
          ),
        ),

        // 🔄 RENDERING PIPELINE FOR LIVE LIST
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
              : RefreshIndicator(
            onRefresh: _fetchMidWeekEvents,
            child: filtered.isEmpty
                ? const Center(child: Text('No midweek events found.'))
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
    final String postedBy = item['senderName'] ?? item['postedBy'] ?? 'Cathedral Admin';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      height: 180,
      child: Stack(
        children: [
          // Picsum background image layer
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

          // THE MULTI-DIRECTIONAL FADE GOGGLES
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.black.withValues(alpha: 0.50),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // 🏷️ TOP-RIGHT CATEGORY DISPLAY CHIP
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: Text(
                _formatCategoryLabel(item['midweekCategory'] ?? item['MidweekCategory']),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),

          // CARD CONTENT
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
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['content'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.2),
                      ),
                      const SizedBox(height: 8),

                      // POSTED BY:
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 12, color: Colors.greenAccent),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'By: $postedBy',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: Colors.greenAccent, fontWeight: FontWeight.bold),
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
                    errorBuilder: (c, e, s) => const Icon(Icons.church, color: Colors.greenAccent),
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