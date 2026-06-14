import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:untitled/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/more_options_drawer.dart';
import 'package:untitled/welcome_screen.dart';
import 'package:untitled/profile_screen.dart';
import 'package:untitled/event_details_screen.dart';
import 'package:untitled/notes_screen.dart';
import 'package:untitled/session_manager.dart';
import 'package:untitled/cathedral_project_screen.dart';
import 'package:untitled/live_events_screen.dart';


import 'package:http/http.dart' as http;
import 'dart:convert';

import 'notification_hub.dart';
import 'notification_service.dart';
class SwitchToProfileTabNotification extends Notification {}

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);


  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  final SharedPreferences rootprefs = await SharedPreferences.getInstance();
  await SessionManager.initializeEngine(rootprefs);
  await NotificationHub.instance.initializeHubCache();
  final bool isLoggedIn = rootprefs.getBool('isLoggedIn') ?? false;

  print("🏁 THE FINAL HANDSHAKE: Auth -> $isLoggedIn | Active Identity Token -> ${SessionManager.currentUserId}");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('📡 Foreground FCM Message Received!');
    if (message.notification != null) {
      NotificationHub.instance.receiveForegroundNotification(
        message.notification!.title ?? 'ACK Cathedral Update',
        message.notification!.body ?? 'Click to see what is happening today.',
      );
    }
  });
  await NotificationService().initialize();

  runApp(ACKstJamesCathedralApp(isLoggedIn: isLoggedIn));
}


class ACKstJamesCathedralApp extends StatelessWidget {

  final bool isLoggedIn;
  const ACKstJamesCathedralApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: SessionManager.themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'St. James Cathedral App',
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0D47A1),
              brightness: Brightness.light,
            ),

            primaryColor: const Color(0xFF0D47A1),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.amberAccent,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.black),
              titleTextStyle: TextStyle(color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),

          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0D47A1),
              brightness: Brightness.dark,
            ),
          ),
          themeMode: currentMode,
          home: isLoggedIn ? const HomeScreen() : const WelcomeScreen(),
          builder: (context, extendChild) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.noScaling),
              child: SafeArea(
                top: false,
                bottom: false,
                child: extendChild!,
              ),
            );
          },

        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _bottomNavPages = [
    const EventsTabBarView(),
    const LiveEventsScreen(),
    const CathedralProjectScreen(),
    const NotesPage(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
      },
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: SafeArea(
          child: NotificationListener<SwitchToProfileTabNotification>(
            onNotification: (notification) {
              setState(() {
                _currentIndex = 4;
              });
              return true;
            },
            child: _bottomNavPages[_currentIndex],
          ),
        ),
        endDrawer: const MoreOptionsDrawer(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.shifting,
          selectedItemColor: const Color(0xFF0D47A1),
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.live_tv), label: 'Live Events'),
            BottomNavigationBarItem(icon: Icon(Icons.apartment), label: 'The Grand Project'),
            BottomNavigationBarItem(icon: Icon(Icons.edit_note), label: 'My Notes'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'You'),
          ],
        ),
      ),
    );
  }
}

class EventsTabBarView extends StatefulWidget {
  const EventsTabBarView({super.key});

  @override
  State<EventsTabBarView> createState() => _EventsTabBarViewState();
}

class _EventsTabBarViewState extends State<EventsTabBarView> {

  String _currentUserName = "Member";

  @override
  void initState() {
    super.initState();
    _loadActiveMemberName();
  }

  void _showNotificationHistorySheet(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cathedral Notifications',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87
                  ),
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                    valueListenable: NotificationHub.instance.messagesList,
                    builder: (context, messages, child) {
                      if (messages.isEmpty) {
                        return const Center(
                          child: Text(
                            'No recent notifications received yet.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                            leading: CircleAvatar(
                              backgroundColor: isDark ? const Color(0xFF1A2638) : Colors.blue.shade50,
                              child: const Icon(Icons.church_rounded, color: Colors.blueAccent),
                            ),
                            title: Text(
                              msg['title'] ?? 'ACK Cathedral Update',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87
                              ),
                            ),
                            subtitle: Text(
                              msg['body'] ?? '',
                              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Future<void> _loadActiveMemberName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedName = prefs.getString('userName');

      if (savedName != null && savedName.isNotEmpty) {
        setState(() {

          _currentUserName = savedName.split(' ')[0];
        });
      }
    } catch (e) {
      print("Error loading member name cache: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(

          title: Text('Praise the Lord $_currentUserName!'),
          actions: [


            ValueListenableBuilder<int>(
              valueListenable: NotificationHub.instance.unreadCount,
              builder: (context, unreadCountValue, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                          unreadCountValue > 0
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_none_rounded,
                          color: unreadCountValue > 0 ? const Color(0xFFFF0000 ) : Colors.white
                      ),
                      onPressed: () {

                        NotificationHub.instance.markAllAsRead();


                        _showNotificationHistorySheet(context);
                      },
                    ),


                    if (unreadCountValue > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$unreadCountValue',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),


            GestureDetector(
              onTapDown: (TapDownDetails details) async {
                final RenderBox button = context.findRenderObject() as RenderBox;
                final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;

                final RelativeRect position = RelativeRect.fromRect(
                  Rect.fromPoints(
                    details.globalPosition,
                    details.globalPosition,
                  ),
                  Offset.zero & overlay.size,
                );

                if (!context.mounted) return;

                await showMenu<String>(
                  context: context,
                  position: position,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  color: Colors.white,
                  items: [
                    PopupMenuItem<String>(
                      enabled: false,
                      child: SizedBox(
                        width: 160,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentUserName.isNotEmpty ? _currentUserName : "Member Account",
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Divider(color: Colors.grey.shade200, thickness: 1),
                            const SizedBox(height: 4),

                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();

                                SwitchToProfileTabNotification().dispatch(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                color: Colors.transparent,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Text(
                                      'More',
                                      style: TextStyle(
                                        color: Color(0xFF0D47A1),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_right,
                                      color: Color(0xFF0D47A1),
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: CircleAvatar(
                  backgroundColor: const Color(0xFF0D47A1),
                  radius: 18,
                  child: Text(
                    _currentUserName.isNotEmpty ? _currentUserName[0].toUpperCase() : "M",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Color(0xFF0D47A1),
            labelColor: Colors.black,
            unselectedLabelColor: Colors.blue,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: [
              Tab(text: "Events"),
              Tab(text: "Other Activities"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            EventsPage(),
            OtherActivitiesPage(),
          ],
        ),
      ),
    );
  }
}




class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _allServerEvents = [];
  List<dynamic> _serverEvents = [];
  bool _isLoading = true;
  bool _isNewestFirst = true;

  final String _apiUrl = "https://cathedral-backend-server-files-6.onrender.com/api/events/all";

  @override
  void initState() {
    super.initState();
    _fetchLiveCathedralEvents();


    _searchController.addListener(_executeLocalSearchFilter);
  }

  @override
  void dispose() {
    _searchController.removeListener(_executeLocalSearchFilter);
    _searchController.dispose();
    super.dispose();
  }
  void _toggleEventSort() {
    setState(() {
      _isNewestFirst = !_isNewestFirst;

      if (_isNewestFirst) {
        // Sort by ID Descending.
        _serverEvents.sort((a, b) => (b['id'] ?? 0).compareTo(a['id'] ?? 0));
      } else {

        _serverEvents.sort((a, b) => (a['id'] ?? 0).compareTo(b['id'] ?? 0));
      }
    });
  }

  void _executeLocalSearchFilter() {
    final String query = _searchController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {

        _serverEvents = List.from(_allServerEvents);
      } else {
        _serverEvents = _allServerEvents.where((event) {
          final String eventTitle = (event['eventTitle'] ?? '').toString().toLowerCase();
          final String description = (event['description'] ?? '').toString().toLowerCase();

          return eventTitle.contains(query) || description.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _handleRefreshEventStream() async {
    print('🔄 Cathedral User pulled to refresh the events dashboard...');
    await _fetchLiveCathedralEvents();
  }


  Future<void> _fetchLiveCathedralEvents() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode == 200) {
        if (!mounted) return;

        final List<dynamic> decodedData = jsonDecode(response.body);

        setState(() {
          _allServerEvents = decodedData;
          _isLoading = false;
        });
        _executeLocalSearchFilter();
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: 'Search for events...',
              hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
              prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () => _searchController.clear(),
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Showing: ${_isNewestFirst ? 'Newest Uploads' : 'Oldest Uploads'}",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton.icon(
                  onPressed: _toggleEventSort,
                  icon: Icon(
                    _isNewestFirst ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 16,
                    color: const Color(0xFF0D47A1), // Matches your brand blue
                  ),
                  label: Text(
                    "Sort Order",
                    style: TextStyle(
                      color: const Color(0xFF0D47A1),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    backgroundColor: Colors.blue.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Upcoming events.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.redAccent),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              color: const Color(0xFF0D47A1),
              backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              onRefresh: _handleRefreshEventStream,
              child: _serverEvents.isEmpty
                  ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                  Center(
                    child: Text(
                      _searchController.text.isNotEmpty
                          ? 'No events match your search term.'
                          : 'No internet connection or events are not ready.\nPull down to try again!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              )
                  : ListView.builder(

                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _serverEvents.length,
                itemBuilder: (context, index) {
                  final event = _serverEvents[index];
                  return buildEventCard(event); // end of return buildEventCard
                },
              ),
            ),
          )
        ],
      ),
    );
  } // end of Widget build

  Widget buildEventCard(Map<String, dynamic> event) {
    final int id = event['id'] ?? 0;
    final String title = event['eventTitle'] ?? 'Cathedral Service';
    final String fullDescription = event['description'] ?? 'Join us in fellowship';
    final String? imageUrl = event['imageUrl']; // Fetched dynamically from Render PostgreSQL DB


    String displayDescription = fullDescription;
    if (displayDescription.length > 60) {
      displayDescription = "${displayDescription.substring(0, 60)}...";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFF0D47A1),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // DYNAMIC IMAGE
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white70),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print(" Image network error on event '$title': $error");
                  print(" Event Map Data: $event");
                  // DEFAULT IMAGE
                  return Image.asset(
                    'assets/icim/ann.png',
                    fit: BoxFit.cover,
                  );
                },
              )
                  : Image.asset(
                'assets/icim/ann.png',
                fit: BoxFit.cover,
              ),
            ),
          ),


          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.15),
                  Colors.black.withOpacity(0.80),
                ],
              ),
            ),
          ),

          // MAIN CARD CONTENT
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [


                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_outlined, color: Colors.amberAccent, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            "Date: Upcoming Service",
                            style: TextStyle(
                              color: Colors.amber.shade200,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        displayDescription, // 60-character trimmed
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade300,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // INTERACTIVE FLOATING ACK SIGN LOGO (Tapping views full text on details screen)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventDetailsScreen(eventItem: event), // Receives full payload
                      ),
                    ).then((value) {
                      _fetchLiveCathedralEvents(); // Reloads list when coming back
                    });
                  },
                  child: Image.asset(
                    'assets/icim/cathsign.jpg',
                    height: 55,
                    width: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.church,
                        color: Colors.amberAccent,
                        size: 36,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} // end of _EventsPageState class



class OtherActivitiesPage extends StatefulWidget {
  const OtherActivitiesPage({super.key});

  @override
  State<OtherActivitiesPage> createState() => _OtherActivitiesPageState();
}

class _OtherActivitiesPageState extends State<OtherActivitiesPage> {
  final TextEditingController _searchController = TextEditingController();


  List<dynamic> _allAnnouncements = [];
  List<dynamic> _allBishopSchedules = [];


  List<dynamic> _announcements = [];
  List<dynamic> _bishopSchedules = [];
  bool _isLoading = true;


  final String _apiUrl = "https://cathedral-backend-server-files-6.onrender.com/api/events/all";

  @override
  void initState() {
    super.initState();
    _fetchOtherActivities();


    _searchController.addListener(_executeActivitiesFilter);
  }

  @override
  void dispose() {
    _searchController.removeListener(_executeActivitiesFilter);
    _searchController.dispose();
    super.dispose();
  }


  void _executeActivitiesFilter() {
    final String query = _searchController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        // Restore fully cached arrays immediately if text field is empty
        _announcements = List.from(_allAnnouncements);
        _bishopSchedules = List.from(_allBishopSchedules);
      } else {
        // Filter Announcements stream inline
        _announcements = _allAnnouncements.where((item) {
          final String title = (item['eventTitle'] ?? '').toString().toLowerCase();
          final String desc = (item['description'] ?? '').toString().toLowerCase();
          return title.contains(query) || desc.contains(query);
        }).toList();

        // Filter Bishop Schedules stream inline
        _bishopSchedules = _allBishopSchedules.where((item) {
          final String title = (item['eventTitle'] ?? '').toString().toLowerCase();
          final String desc = (item['description'] ?? '').toString().toLowerCase();
          return title.contains(query) || desc.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _handleRefreshActivitiesStream() async {
    await _fetchOtherActivities();
  }

  Future<void> _fetchOtherActivities() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> allData = jsonDecode(response.body);

        if (!mounted) return;
        setState(() {
          // Commit stream updates directly to reference storage structures
          _allAnnouncements = allData.where((item) => item['updateType'] == 'ANNOUNCEMENT').toList();
          _allBishopSchedules = allData.where((item) => item['updateType'] == 'BISHOP_SCHEDULE').toList();
          _isLoading = false;
        });


        _executeActivitiesFilter();
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [

        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 4.0),
          child: TextField(
            controller: _searchController,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: 'Search announcements & schedules...',
              hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
              prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () => _searchController.clear(),
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),

        // MAIN ADAPTIVE CONTENT LISTENER
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFF0D47A1),
            backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            onRefresh: _handleRefreshActivitiesStream,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              children: [
                //  ANNOUNCEMENTS
                Text(
                  'Announcements',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                ),
                const SizedBox(height: 10),
                if (_announcements.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Text(
                      _searchController.text.isNotEmpty
                          ? 'No matching announcements found.'
                          : 'No active church announcements available.',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ..._announcements.map((item) {
                    return Card(
                      color: isDark ? const Color(0xFF1E1E24) : Colors.yellow.shade50,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.campaign, color: Colors.orange),
                        title: Text(
                          item['eventTitle'] ?? 'Announcement',
                          style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
                        ),
                        subtitle: Text(
                          item['description'] ?? '',
                          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 20),

                // BISHOP SCHEDULES
                Text(
                  'Bishop Schedule',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                ),
                const SizedBox(height: 10),
                if (_bishopSchedules.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Text(
                      _searchController.text.isNotEmpty
                          ? 'No matching visitation tracks.'
                          : 'No upcoming bishop visitations scheduled.',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ..._bishopSchedules.map((item) {
                    String displayDate = "Visits";
                    if (item['eventDate'] != null && item['eventDate'].toString().length >= 10) {
                      displayDate = item['eventDate'].toString().substring(5, 10).replaceAll('-', '/');
                    }

                    return Card(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.workspace_premium, color: Colors.purple),
                        title: Text(
                          item['eventTitle'] ?? 'Confirmation Service',
                          style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
                        ),
                        subtitle: Text(
                          item['description'] ?? '',
                          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.purple.withOpacity(0.2) : Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            displayDate,
                            style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}