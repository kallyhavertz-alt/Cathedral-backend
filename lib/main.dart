import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/welcome_screen.dart';
import 'package:untitled/profile_screen.dart';
//import 'package:untitled/register_screen.dart';
import 'package:untitled/notes_screen.dart';


// 1. THE ROOT ENTRY POINT OF THE APPLICATION
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(ACKstJamesCathedralApp(isLoggedIn: isLoggedIn));
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
        // Premium Cathedral Navy Blue Theme color
        primaryColor: const Color(0xFF0D47A1),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        useMaterial3: true,
      ),
      // Uses the local storage persistence flag to route the user
      home: isLoggedIn ? const HomeScreen() : const WelcomeScreen(),
    );
  }
}

// 2. THE MAIN FRAME WITH BOTTOM NAVIGATION
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _bottomNavPages = [
    const EventsTabBarView(), // Houses the swappable top tabs
    const Center(child: Text('Live Events appear here', style: TextStyle(fontSize: 18))),
    const Center(child: Text('The Grand Project', style: TextStyle(fontSize: 18))),
    const NotesPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // this disables the default back button
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
      },
    child:  Scaffold(
      body: SafeArea(child: _bottomNavPages[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
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

// 3. THE TOP SLIDING TABS VIEW (Events vs Other Activities)
class EventsTabBarView extends StatelessWidget {
  const EventsTabBarView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Praise the Lord Kally!'),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.black),
              onPressed: () {},
            ),
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                backgroundColor: Colors.grey,
                radius: 16,
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            )
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
            EventsPage(),          // Left Screen
            OtherActivitiesPage(), // Right Screen (Swiped)
          ],
        ),
      ),
    );
  }
}

// 4. THE EVENTS FEED PAGE
class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

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
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Upcoming events.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.redAccent),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: [
                buildEventCard('Sunday Service', 'Palm Sunday!', Icons.church),
                buildEventCard('Youth overnight praise', 'KAYO Night of Praise', Icons.music_note),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget buildEventCard(String title, String subtitle, IconData icon) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red.shade200, width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade50,
            child: Icon(icon, color: const Color(0xFF0D47A1)),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ),
      ),
    );
  }
}

// 5. THE OTHER ACTIVITIES PAGE
class OtherActivitiesPage extends StatelessWidget {
  const OtherActivitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text('Announcements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Card(
          color: Colors.yellow.shade50,
          child: const ListTile(
            leading: Icon(Icons.campaign, color: Colors.orange),
            title: Text('Mothers Union Meeting'),
            subtitle: Text('All members are reminded of the meeting this Sunday after the second service.'),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Bishop Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: const Icon(Icons.workspace_premium, color: Colors.purple),
            title: const Text('Confirmation Service'),
            subtitle: const Text('Rt. Rev. Bishop visiting St. James Cathedral for mass confirmation.'),
            trailing: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(8)),
              child: const Text('June 14', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }
}