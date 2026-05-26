import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/welcome_screen.dart'; // Ensure this matches your file name

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _userName = 'Loading...';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'Cathedral Member';
      _userEmail = prefs.getString('userEmail', ) ?? 'james@cathedral.org';
    });
  }

  // 📝 THE POP-UP ALERT DIALOG FUNCTION
  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Must tap a button to dismiss
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 10),
              Text('Log Out'),
            ],
          ),
          content: const Text('Are you sure you want to log out of your Cathedral account?'),
          actions: [
            // NO BUTTON -> Stays in the app
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('No, Stay', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),

            // YES BUTTON -> Clears state and logs out completely
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close dialog sheet

                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', false); // Wipe storage flag

                if (!context.mounted) return;

                // Clear background stack and route back to Welcome Screen gateway
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                      (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Yes, Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Layout: User details (Left) vs Menu & Avatar (Right Column)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12), // Balances text with top menu icon line
                    Text(
                      _userName,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userEmail,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 🚀 THE SKETCH MENU BUTTON (Hamburger Menu)
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.black87, size: 28),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      // Action for menu button tap later
                    },
                  ),
                  const SizedBox(height: 12),

                  // Profile Initial Avatar Circle
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFF0D47A1).withOpacity(0.1),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFF0D47A1),
                      child: Text(
                        _userName.isNotEmpty ? _userName[0].toUpperCase() : 'K',
                        style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF0D47A1).withOpacity(0.3)),
            ),
            child: const Text('ACK St. James Cathedral', style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              _buildQuickActionCard(icon: Icons.bookmark_border_rounded, label: 'Saved', color: const Color(0xFF0D47A1), onTap: () {}),
              const SizedBox(width: 16),

              // 🚀 LOGOUT CARD WITH CONFIRMATION PROMPT
              _buildQuickActionCard(
                icon: Icons.logout_rounded,
                label: 'Logout',
                color: Colors.redAccent,
                onTap: () {
                  _showLogoutConfirmationDialog(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 35),
          const Text('Account Management', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: [
                _buildSettingsListTile(Icons.settings_outlined, 'Settings'),
                _buildSettingsListTile(Icons.edit_outlined, 'Edit profile'),
                _buildSettingsListTile(Icons.campaign_outlined, 'Main events'),
                _buildSettingsListTile(Icons.info_outline_rounded, 'About us'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsListTile(IconData icon, String title) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF0D47A1)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {},
      ),
    );
  }
}