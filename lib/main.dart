import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:untitled/deep_link_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:untitled/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/more_options_drawer.dart';
import 'package:untitled/staff_login_screen.dart';
import 'package:untitled/staff_workspace_screen.dart';
import 'package:untitled/sunday_services_page.dart';
import 'package:untitled/welcome_screen.dart';
import 'package:untitled/profile_screen.dart';
import 'package:untitled/notes_screen.dart';
import 'package:untitled/session_manager.dart';
import 'package:untitled/cathedral_project_screen.dart';
import 'package:untitled/bb_text_formatter.dart';

import 'announcements_sreen.dart';
import 'bishop_schedule_screen.dart';
import 'live_and_posts_dashboard.dart';
import 'mid_week_events_page.dart';
import 'notification_hub.dart';
import 'notification_service.dart';
import 'other_ministries_page.dart';

class SwitchToProfileTabNotification extends Notification {}
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("🔥 BACKGROUND FCM MESSAGE PACKET ARRIVED: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  final SharedPreferences rootprefs = await SharedPreferences.getInstance();
  print("Trace 2: SharedPreferences ready.");
  await SessionManager.initializeEngine(rootprefs);
  print("🕵️‍♂️ TRACE 3: SessionManager ready. Initializing Hub Cache...");
  await NotificationHub.instance.initializeHubCache();
  print("🕵️‍♂️ TRACE 4: Hub Cache ready. Reading login bit...");
  final bool isLoggedIn = rootprefs.getBool('isLoggedIn') ?? false;
  print("🏁 THE FINAL HANDSHAKE: Auth -> $isLoggedIn | Active Identity Token -> ${SessionManager.currentUserId}");

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    NotificationService().initialize();
    print("🔥 Firebase initialized. Notification service running in background.");
  } catch (networkError) {
    print("⚠️ Offline Startup Mode active: App skipped online initialization hooks ($networkError)");
  }


  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    try {
      print('📡 Foreground FCM Message Received!');
      print('📦 Raw Notification Block: ${message.notification}');
      print('📦 Raw Data Map Payload: ${message.data}');

      String? alertTitle;
      String? alertBody;
      String categoryType = 'GENERAL';

      String createdAtTimeStr = DateTime.now().toIso8601String();

      if (message.notification != null) {
        alertTitle = message.notification!.title;
        alertBody = message.notification!.body;
      }

       if (message.data.isNotEmpty) {
        print('📦 Extracting fields from silent Data Payload parameters...');
        alertTitle ??= message.data['title'];
        alertBody ??= message.data['body'];

        // 🛡️ Robust key extraction from payload to prevent 'GENERAL' fallback
        final String? rawCategory = message.data['category_type'] ?? 
                                    message.data['categoryType'] ?? 
                                    message.data['postType'] ?? 
                                    message.data['type'];
                                    
        if (rawCategory != null) {
          categoryType = rawCategory.toString().trim().toUpperCase();
        }

        print("messagedata parsing complete: ${message.data} | Extracted Category: $categoryType");
      }
      if (message.data.containsKey('created_at') && message.data['created_at'] != null) {
        createdAtTimeStr = message.data['created_at'].toString();
      }

      print("📥 Pushing cleanly extracted parameters to Hub: [Category: $categoryType]");
      print(message.data);

      alertTitle ??= 'ACK Cathedral Update';
      alertBody ??= 'Click to see what is happening today.';

      NotificationHub.instance.receiveForegroundNotification(alertTitle, alertBody, categoryType, createdAtTimeStr);


      final overlayState = navigatorKey.currentState?.overlay;
      if (overlayState != null) {
        showTopPoppingBannerWithState(overlayState, alertTitle, alertBody);
      } else {
        print("⚠️ Navigator Overlay State was not ready yet, overlay skipped.");
      }

    } catch (error, stackTrace) {
      print("🚨 ERROR IN FOREGROUND PARSING: $error");
      print("📋 STACK TRACE: $stackTrace");
    }
  });

  AppSessionPalette.initializeSessionColor();
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
          scaffoldMessengerKey: scaffoldMessengerKey,
          navigatorKey: navigatorKey,
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
              iconTheme: IconThemeData(color: Colors.greenAccent),
              titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
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
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
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

  late final List<Widget> _bottomNavPages = [
    const EventsTabBarView(),

    LiveAndPostsDashboard(
      currentMemberId: SessionManager.currentUserId,
    ),
    const CathedralProjectScreen(),
    const NotesPage(),
    ProfileScreen(
      onAvatarUpdated: (newServerPath) {
        setState(() {
          _navBarAvatarPath = newServerPath;
        });
      },
    ),
  ];

  String? _navBarAvatarPath;


  @override
  void initState() {
    super.initState();
    _loadNavbarAvatar();
    _fetchNavBarAvatarFromServer();
WidgetsBinding.instance.addPostFrameCallback((_) {
DeepLinkService().initDeepLinks(context);
  });
    }

  Future<void> _fetchNavBarAvatarFromServer() async {
    try {
      final String targetUrl = 'http://192.168.100.33:8080/api/v1/community/user/${SessionManager.currentUserId}';
      final response = await http.get(Uri.parse(targetUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> userData = json.decode(response.body);
        setState(() {
          _navBarAvatarPath = userData['profilePictureUrl'];
        });
      }
    } catch (e) {
      debugPrint("🚨 Nav Bar avatar retrieval failed: $e");
    }
  }
  Future<void> _loadNavbarAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final String storageKey = 'user_avatar_path_${SessionManager.currentUserId}';
    setState(() {
      _navBarAvatarPath = prefs.getString(storageKey);
    });
  }

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
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            const BottomNavigationBarItem(icon: Icon(Icons.live_tv), label: 'Live Events'),
            const BottomNavigationBarItem(icon: Icon(Icons.apartment), label: 'The Grand Project'),
            const BottomNavigationBarItem(icon: Icon(Icons.edit_note), label: 'My Notes'),
           // BottomNavigationBarItem(icon: Icon(Icons.person), label: 'You'),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: _currentIndex == 4
                          ? const Color(0xFF0D47A1)
                          : Colors.transparent,
                      width: 1.5
                  ),
                ),
                child: CircleAvatar(
                  radius: 11,
                  backgroundColor: Colors.blueGrey[300],
                  // 🟩 Checks if a network string exists on our backend server
                  backgroundImage: (_navBarAvatarPath != null && _navBarAvatarPath!.isNotEmpty)
                      ? NetworkImage('http://192.168.100.33:8080$_navBarAvatarPath')
                      : null,
                  child: (_navBarAvatarPath == null || _navBarAvatarPath!.isEmpty)
                      ? const Icon(Icons.person, size: 14, color: Colors.white)
                      : null,
                ),
              ),
              label: 'You',
            ),
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

  Widget _buildMenuRow(IconData icon, String title, {bool isHighlight = false}) {
    final Color rowColor = isHighlight ? const Color(0xFF0D47A1) : Colors.black87;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      color: Colors.transparent,
      child: Row(
        children: [
          Icon(icon, color: rowColor, size: 18),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: rowColor,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNotificationTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return "";
    try {
      final DateTime notificationDate = DateTime.parse(isoString).toLocal();
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(notificationDate);

      if (difference.inMinutes < 1) {
        return "Just now";
      } else if (difference.inMinutes < 60) {
        return "${difference.inMinutes}m ago";
      } else if (difference.inHours < 24) {
        return "${difference.inHours}h ago";
      } else {
         return "${notificationDate.day}/${notificationDate.month}/${notificationDate.year}";
      }
    } catch (e) {
      return "";
    }
  }

  void _showNotificationHistorySheet(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: NotificationHub.instance.messagesList,
              builder: (context, notifications, child) {
                if (notifications.isEmpty) {
                  return Center(
                    child: Text(
                      "No notifications yet.",
                      style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 16),
                    ),
                  );
                }

                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Text(
                      "Cathedral notifications",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final alert = notifications[index];

                          // Note: Ensuring you pull whatever key your NotificationHub passes down
                          final String category = alert['updateType'] ?? alert['category_type'] ?? 'GENERAL';
                          final bool isEaglesLink = category == 'EAGLES_LINK';

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isEaglesLink
                                    ? const Color(0xFF0D47A1).withValues(alpha: 0.5)
                                    : (isDark ? Colors.white10 : Colors.grey.shade100),
                                width: isEaglesLink ? 1.5 : 1,
                              ),
                              boxShadow: isEaglesLink
                                  ? [BoxShadow(color: const Color(0xFF0D47A1).withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 3))]
                                  : null,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 46,
                                    height: 46,
                                    color: isDark ? Colors.white54.withValues(alpha: 0.05) : Colors.grey.shade200,
                                    child: Image.asset(
                                      _determineCategoryThumbnail(category),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Icon(
                                          Icons.notifications_active_outlined,
                                          color: isDark ? Colors.blue.shade300 : const Color(0xFF0D47A1)
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 🟩 A Row layout to balance Title on the left and Timestamp on the right
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              alert['title'] ?? 'ACK Cathedral Update',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: isEaglesLink
                                                    ? (isDark ? Colors.blue.shade300 : const Color(0xFF0D47A1))
                                                    : (isDark ? Colors.white70 : Colors.black87),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // 🕒 THE NEW TIMESTAMP INJECTOR
                                          Text(
                                            _formatNotificationTime(alert['created_at']),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w400,
                                              color: isDark ? Colors.white38 : Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      BBText(
                                        text: alert['body'] ?? '',
                                        charLimit: 40,
                                        fontSize: 13,
                                        color: isDark ? Colors.white60 : Colors.grey.shade700,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  String _determineCategoryThumbnail(String? categoryType) {
    print("🎨 UI Image Router received category string: '$categoryType'");

    if (categoryType == null || categoryType.isEmpty) {
      return 'assets/icons/default.png';
    }

    switch (categoryType.trim().toUpperCase()) {
      case 'SUNDAY_SERVICE':
      case 'SUNDAY_SERVICES':
        return 'assets/icons/dropped.png';

      case 'STAFF_NOTICE':
      case 'INTERNAL_STAFF_ALERT':
        return 'assets/icons/staff_notice.png';

      case 'BISHOP_SPECIAL':
      case 'PASTORAL_LETTER':
        return 'assets/icons/bishop.png';

      case 'EVENT':
      case 'EVENTS':
      case 'GENERALEVENT':
        return 'assets/icons/announce.png';

      case 'EAGLES_LINK':
        return 'assets/icons/eagles.jpg';

      case 'ANNOUNCEMENT':
      case 'ANNOUNCEMENTS':
      default:
        return 'assets/icons/default.png';
    }
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
      length: 3,
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
                          color: unreadCountValue > 0 ? const Color(0xFFFF0000) : Colors.white
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
                          decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            '$unreadCountValue',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
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
                final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;

                final RelativeRect position = RelativeRect.fromRect(
                  Rect.fromPoints(details.globalPosition, details.globalPosition),
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
                        width: 180,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentUserName.isNotEmpty ? _currentUserName : "Member Account",
                              style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.bold),
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
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                color: Colors.transparent,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Text('More', style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.w600, fontSize: 14)),
                                    Icon(Icons.arrow_right, color: Color(0xFF0D47A1), size: 20),
                                  ],
                                ),
                              ),
                            ),
                            Divider(color: Colors.grey.shade100, thickness: 1),
                            const SizedBox(height: 4),

                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AnnouncementsScreen()));
                              },
                              child: _buildMenuRow(Icons.campaign_outlined, 'Announcements'),
                            ),
                            const SizedBox(height: 8),

                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const BishopScheduleScreen()));
                              },
                              child: _buildMenuRow(Icons.event_note_outlined, 'Bishop Schedule'),
                            ),
                            const SizedBox(height: 8),

                            GestureDetector(
                              onTap: () async {
                                Navigator.of(context).pop();
                                final SharedPreferences prefs = await SharedPreferences.getInstance();
                                final bool isStaffRegistered = prefs.getBool('isStaffRegistered') ?? false;
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => isStaffRegistered ? const StaffWorkspaceScreen() : const StaffLoginScreen(),
                                  ),
                                );
                              },
                              child: _buildMenuRow(Icons.admin_panel_settings_outlined, 'Staff Gateway', isHighlight: true),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0, left: 8.0),
                child: Center(
                  child: CircleAvatar(
                    backgroundColor: AppSessionPalette.activeSessionColor,
                    radius: 18,
                    child: Text(
                      _currentUserName.isNotEmpty ? _currentUserName[0].toUpperCase() : "M",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Color(0xFF0D47A1),
            labelColor: Colors.greenAccent,
            unselectedLabelColor: Colors.blue,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: [
              Tab(text: "Sunday Services"),
              Tab(text: "Mid-week Events"),
              Tab(text: "Other Ministries"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SundayServicesPage(),
            MidWeekEventsPage(),
            OtherMinistriesPage(),
          ],
        ),
      ),
    );
  }
}


void showTopPoppingBannerWithState(OverlayState overlayState, String title, String body) {
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) {
      return _TopPoppingBannerWidget(
        title: title,
        body: body,
        onDismiss: () => overlayEntry.remove(),
      );
    },
  );

  overlayState.insert(overlayEntry);
}

class _TopPoppingBannerWidget extends StatefulWidget {
  final String title;
  final String body;
  final VoidCallback onDismiss;

  const _TopPoppingBannerWidget({
    required this.title,
    required this.body,
    required this.onDismiss,
  });

  @override
  State<_TopPoppingBannerWidget> createState() => _TopPoppingBannerWidgetState();
}

class _TopPoppingBannerWidgetState extends State<_TopPoppingBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    );

    _widthAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.fastOutSlowIn),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    DeepLinkService().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Positioned(
      top: mediaQuery.padding.top + 12,
      left: 12,
      right: 12,
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: mediaQuery.size.width * (0.4 + (0.6 * _widthAnimation.value)),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D47A1),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.body,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}