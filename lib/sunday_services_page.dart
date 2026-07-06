import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'event_details_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'file_download_service.dart';
import 'bb_text_formatter.dart';

class SundayServicesPage extends StatefulWidget {
  const SundayServicesPage({Key? key}) : super(key: key);

  @override
  State<SundayServicesPage> createState() => _SundayServicesPageState();
}

class _SundayServicesPageState extends State<SundayServicesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isNewestFirst = true;
  String _selectedSubService = "All Services";

  // 📡 Network Connection States
  List<dynamic> _liveServices = [];
  bool _isLoading = true;
  String _errorMessage = "";

  final List<String> _subServiceOptions = [
    "All Services",
    "Kikuyu",
    "Kiswahili",
    "English",
    "Main Kikuyu"
  ];

  @override
  void initState() {
    super.initState();
    _fetchSundayServices();
  }

  // 📡 Live API Request Hook
  Future<void> _fetchSundayServices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final Uri url = Uri.parse('http://192.168.100.33:8080/api/v1/posts?type=SUNDAY_SERVICE');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          _liveServices = jsonDecode(response.body);
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
        _errorMessage = "Connection dropped. Make sure you are connected to the internet.";
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
    // 🔍 1. Filter by Search Query & Dropdown Sub-Service Selection
    List<dynamic> filtered = _liveServices.where((item) {
      final matchesSearch = "${item['title']} ${item['content']}"
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());

      final String itemSubService = (item['subService'] ?? "").toString().toUpperCase();
      final String currentSelection = _selectedSubService.toUpperCase();

      final bool matchesDropdown = _selectedSubService == "All Services" ||
          itemSubService == currentSelection ||
          itemSubService.contains(currentSelection);

      return matchesSearch && matchesDropdown;
    }).toList();

    // 🔄 2. Apply Sorting Rules
    filtered.sort((a, b) => _isNewestFirst
        ? b['id'].compareTo(a['id'])
        : a['id'].compareTo(b['id']));

    final Color primaryColor = const Color(0xFF0D47A1);

    return Column(
      children: [
        // 🔍 SEARCH BAR
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search Sunday services...',
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

        // 🎯 SUB-SERVICES FILTER DROPDOWN
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSubService,
                isExpanded: true,
                icon: Icon(Icons.filter_list_rounded, color: primaryColor),
                style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 14
                ),
                dropdownColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() => _selectedSubService = newValue);
                  }
                },
                items: _subServiceOptions.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
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
            onRefresh: _fetchSundayServices,
            child: filtered.isEmpty
                ? const Center(child: Text('No matching services found.'))
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
              itemCount: filtered.length,
              itemBuilder: (context, index) => _buildPicsumItemCard(filtered[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPicsumItemCard(Map<String, dynamic> item) {
    print("DEBUG POST DATA: ${item.toString()}");
    final String uploaderName = _getSenderFirstName(item['senderName'] ?? item['fullName'] ?? 'Staff Member');

    // 🔍 1. Identify if a valid server image url was fetched
    String? fileUrl = item['fileUrl'];
    String isFileType = item['isFileType'] ?? 'TEXT';
    bool hasLiveImage = (isFileType == "IMAGE" && fileUrl != null && fileUrl.isNotEmpty);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(8)
                  ),
                  child: Text(
                    item['subService'].toString().toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item['title'].toString().toUpperCase(),
                  style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  '📅 ${item['formattedDate']} | 🕒 ${item['formattedTime']}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13),
                ),
                const SizedBox(height: 4),
                BBText(
                  text: item['content'] ?? '',
                  charLimit: 40,
                  color: Colors.white70,
                  fontSize: 12,
                ),
                const SizedBox(height: 4),

                // 🎯 UPLOADER BRAND BADGE LINE
                Row(
                  children: [
                    Icon(Icons.person_pin_circle_rounded, color: Colors.blue[300], size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Posted by: $uploaderName',
                      style: TextStyle(
                          color: Colors.blue[100],
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.5
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // FLOATING ACK LOGO DETECTOR
          Positioned(
            bottom: 12,
            right: 12,
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
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset('assets/icim/cathsign.jpg', fit: BoxFit.cover),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
