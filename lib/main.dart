import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/more_options_drawer.dart';
import 'package:untitled/welcome_screen.dart';
import 'package:untitled/profile_screen.dart';
import 'package:untitled/event_details_screen.dart';
import 'package:untitled/notes_screen.dart';
import 'package:untitled/cathedral_project_screen.dart';
import 'package:untitled/live_events_screen.dart';

// MODIFICATION AREA 1: Added networking utilities
import 'package:http/http.dart' as http;
import 'dart:convert';
class SwitchToProfileTabNotification extends Notification {}

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // 🎯 Make the background bars completely transparent
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light, // Adjust to .light if your header is dark
  ));
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(ACKstJamesCathedralApp(isLoggedIn: isLoggedIn));
}
void requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('🎯 Awesome! User allowed notification prompts!');
  } else {
    print('❌ User denied or skipped notification settings.');
  }
}

class ACKstJamesCathedralApp extends StatelessWidget {
  final bool isLoggedIn;
  const ACKstJamesCathedralApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'St. James Cathedral App',
      theme: ThemeData(
        primaryColor: const Color(0xFF0D47A1),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.amberAccent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
            child: SafeArea(
              top: false,
              bottom: false,
              child: child!,
            ),
        );
      },
      home: isLoggedIn ? const HomeScreen() : const WelcomeScreen(),
    );
  } // end of Widget build
} // end of ACKstJamesCathedralApp class

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
                _currentIndex = 4; // Moves explicitly to the ProfileScreen page index
              });
              return true; // Stops the notification right here
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
        ), // end of BottomNavigationBar
      ), // end of Scaffold
    ); // end of return PopScope
  } // end of Widget build
} // end of _HomeScreenState class

class EventsTabBarView extends StatefulWidget {
  const EventsTabBarView({super.key});

  @override
  State<EventsTabBarView> createState() => _EventsTabBarViewState();
}

class _EventsTabBarViewState extends State<EventsTabBarView> {
  // 🎯 Dynamic Name Token Holder (Defaults to Member if not found)
  String _currentUserName = "Member";

  @override
  void initState() {
    super.initState();
    _loadActiveMemberName(); // 🔌 Fetch name from storage disk on initialization
  }

  // 💾 Fetch the name securely from storage hardware memory
  Future<void> _loadActiveMemberName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedName = prefs.getString('userName');

      if (savedName != null && savedName.isNotEmpty) {
        setState(() {
          // Splits full name down to just your first name
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
          // 🎯 MODIFIED: Now dynamically greets the logged-in user!
          title: Text('Praise the Lord $_currentUserName!'),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.black),
              onPressed: () {},
            ),

            // 🎯 CUSTOM ACCOUNT DIALOG BOX (Routes explicitly to ProfilePage)
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

                            // 🚀 CLICKABLE "MORE" CALL TO ACTION
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop(); // Dismisses the popup card dropdown

                                // 🎯 TARGET LINK FIX: Points explicitly to your clean ProfilePage class
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
          ), // end of TabBar
        ), // end of AppBar
        body: const TabBarView(
          children: [
            EventsPage(),
            OtherActivitiesPage(),
          ],
        ), // end of TabBarView
      ), // end of Scaffold
    ); // end of return DefaultTabController
  } // end of Widget build
} // end of EventsTabBarView class


// ====================================================================
// MODIFICATION AREA: The New Live Events Stateful Controller WITH REFRESH
// ====================================================================
class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  List<dynamic> _serverEvents = [];
  bool _isLoading = true;

  // Change this IP string to match your laptop's current network address configuration
  final String _apiUrl = "http://10.34.113.23:8080/api/events/all";

  @override
  void initState() {
    super.initState();
    _fetchLiveCathedralEvents();
  }

  // 🎯 PULL TO REFRESH MANDATE: Handled natively as a returnable Future block
  Future<void> _handleRefreshEventStream() async {
    print('🔄 Cathedral User pulled to refresh the events dashboard...');
    await _fetchLiveCathedralEvents();
  }

  // HTTP Network function to hit Spring Boot Controller
  Future<void> _fetchLiveCathedralEvents() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _serverEvents = jsonDecode(response.body);
          _isLoading = false;
        }); // end of setState
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
      } // end of response checks
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    } // end of try-catch block
  } // end of _fetchLiveCathedralEvents function

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search for events...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ), // end of InputDecoration
          ), // end of TextField
          const SizedBox(height: 20),
          const Text(
            'Upcoming events.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.redAccent),
          ),
          const SizedBox(height: 10),

          // Dynamic Rendering Body Layout Layer
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              color: const Color(0xFF0D47A1),
              backgroundColor: Colors.white,
              onRefresh: _handleRefreshEventStream, // 🎯 Connected cleanly here!
              child: _serverEvents.isEmpty
                  ? ListView(
                // ⚡ Keep the view pullable even when empty
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                  const Center(
                    child: Text(
                      'No internet connection or events are not ready.\nPull down to try again!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              )
                  : ListView.builder(
                // ⚡ Keep view elastic for small service listing cards
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _serverEvents.length,
                itemBuilder: (context, index) {
                  final event = _serverEvents[index];
                  return buildEventCard(event
                    //event['id'],
                   // event['eventTitle'] ?? 'Cathedral Service',
                  //  event['description'] ?? 'Join us in fellowship',
                  //  Icons.church,
                  ); // end of return buildEventCard
                }, // end of itemBuilder lambda
              ), // end of ListView.builder
            ), // end of RefreshIndicator
          ) // end of Expanded
        ], // end of primary Column children array
      ), // end of primary Column widget
    ); // end of return Padding
  } // end of Widget build

  // Interactive Card Render Method Helper
  Widget buildEventCard(Map<String, dynamic> event) {
    final int id = event['id'] ?? 0;
    final String title = event['eventTitle'] ?? 'Cathedral Service';
    final String subtitle = event['description'] ?? 'Join us in fellowship';
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFF0D47A1), // Solid fallback brand color while asset loads
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        image: const DecorationImage(
          // Uses your local asset image folder for Reverend Ann
          image: AssetImage('assets/icim/ann.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // 🕶️ DARK OPACITY OVERLAY SHIELD: Keeps typography perfectly legible
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.15),
                  Colors.black.withOpacity(0.75),
                ],
              ),
            ),
          ),

          // MAIN CARD CONTENT PADDING
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [

                // TEXT CONTENT LAYER (Bottom-Left)
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
                        subtitle,
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

                // 🚀 INTERACTIVE FLOATING ACK SIGN LOGO (Right Side - No surrounding container box)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventDetailsScreen(eventItem: event),
                      ),
                    ).then((value) {
                      _fetchLiveCathedralEvents();
                    });
                  },

                  child: Image.asset(

                    'assets/icim/symbol.png', // The path to your drawn shield logo asset
                    height: 55,            // Clean display size matching the drawing height
                    width: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Graceful text fallback if the image asset isn't added to pubspec.yaml yet
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
  } // end of buildEventCard function
} // end of _EventsPageState class


// ====================================================================
// 🔥 MODIFIED HIGHLIGHT AREA: Dynamic OtherActivitiesPage Stream
// ====================================================================
class OtherActivitiesPage extends StatefulWidget {
  const OtherActivitiesPage({super.key});

  @override
  State<OtherActivitiesPage> createState() => _OtherActivitiesPageState();
}

class _OtherActivitiesPageState extends State<OtherActivitiesPage> {
  List<dynamic> _announcements = [];
  List<dynamic> _bishopSchedules = [];
  bool _isLoading = true;

  // Uses your exact local server endpoint configurations
  final String _apiUrl = "http://10.34.113.23:8080/api/events/all";

  @override
  void initState() {
    super.initState();
    _fetchOtherActivities();
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
          // Filters stream variables contextually based on your database updateType values
          _announcements = allData.where((item) => item['updateType'] == 'ANNOUNCEMENT').toList();
          _bishopSchedules = allData.where((item) => item['updateType'] == 'BISHOP_SCHEDULE').toList();
          _isLoading = false;
        });
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      color: const Color(0xFF0D47A1),
      backgroundColor: Colors.white,
      onRefresh: _handleRefreshActivitiesStream,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        children: [
          // 📢 SECTION 1: ANNOUNCEMENTS
          const Text('Announcements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (_announcements.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Text('No active church announcements available.', style: TextStyle(color: Colors.grey)),
            )
          else
            ..._announcements.map((item) {
              return Card(
                color: Colors.yellow.shade50,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.campaign, color: Colors.orange),
                  title: Text(item['eventTitle'] ?? 'Announcement'),
                  subtitle: Text(item['description'] ?? ''),
                ),
              );
            }),

          const SizedBox(height: 20),

          // 💜 SECTION 2: BISHOP SCHEDULES
          const Text('Bishop Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (_bishopSchedules.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Text('No upcoming bishop visitations scheduled.', style: TextStyle(color: Colors.grey)),
            )
          else
            ..._bishopSchedules.map((item) {
              // Extracting and shortening date string safely if present (e.g. 2026-06-14 -> June 14 approximation)
              String displayDate = "Visits";
              if (item['eventDate'] != null && item['eventDate'].toString().length >= 10) {
                displayDate = item['eventDate'].toString().substring(5, 10).replaceAll('-', '/');
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.workspace_premium, color: Colors.purple),
                  title: Text(item['eventTitle'] ?? 'Confirmation Service'),
                  subtitle: Text(item['description'] ?? ''),
                  trailing: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(8)),
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
    );
  }
}