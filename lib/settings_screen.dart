import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/about_trial_build_screen.dart';
import 'package:untitled/giving_screen.dart';
import 'package:untitled/profile_update_screen.dart';
import 'package:untitled/welcome_screen.dart';
import 'package:untitled/session_manager.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SettingsScreen extends StatelessWidget {
  final String currentName;
  final String currentEmail;
  final String currentLocation;
  final String currentBio;
  final String? currentAvatarPath;
  final Function(String newPath)? onAvatarUpdated;
  const SettingsScreen({
    Key? key,
    required this.currentName,
    required this.currentEmail,
    required this.currentLocation,
    required this.currentBio,
    this.currentAvatarPath,
    this.onAvatarUpdated,
  }) : super(key: key);


  void _showLogoutConfirmationDialog(BuildContext context, bool isDark, Color cardBg, Color mainText) {
    bool isLoggingOut = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: cardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                  const SizedBox(width: 10),
                  Text('Log Out', style: TextStyle(color: mainText)),
                ],
              ),
              content: Text('Are you sure you want to log out of your Cathedral account?',
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
              actions: [
                TextButton(
                  onPressed: isLoggingOut ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('No, Stay', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: isLoggingOut ? null : () async {
                    setModalState(() => isLoggingOut = true);
                    
                    // 🧼 3 Second Delay with Spinner as requested
                    await Future.delayed(const Duration(seconds: 3));

                    // Clear App Cache during logout too
                    try {
                      final tempDir = await getTemporaryDirectory();
                      if (tempDir.existsSync()) {
                        tempDir.deleteSync(recursive: true);
                      }
                    } catch (_) {}

                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('isLoggedIn', false);
                    SessionManager.currentUserId = -1;

                    if (!context.mounted) return;
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
                  child: isLoggingOut 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Yes, Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _navigateToEditProfile(BuildContext context) async {
    // 🛰️ Push to EditProfileScreen using the data passed down from the profile screen
    final bool? dynamicChangesApplied = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          initialName: currentName,
          initialEmail: currentEmail,
          initialLocation: currentLocation,
          initialBio: currentBio,
          initialAvatarPath: currentAvatarPath,
          onAvatarUpdated: onAvatarUpdated,
        ),
      ),
    );

    //If the user hit "Save" and popped back with true, pop back to the profile screen
    //with 'true' so the Profile Screen knows it needs to refresh from the server!
    if (dynamicChangesApplied == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mainTextColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white60 : Colors.grey[600]!;
    final Color cardBackground = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: mainTextColor,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              'Device ID Isolation Node: Active (User #${SessionManager.currentUserId})',
              style: TextStyle(fontSize: 12, color: subTextColor),
            ),
          ),

          // 1. Edit Profile
          ListTile(
            leading: Icon(Icons.person_outline_rounded, color: isDark ? Colors.blue[300] : const Color(0xFF0D47A1)),
            title: Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w500, color: mainTextColor)),
            trailing: Icon(Icons.chevron_right_rounded, color: subTextColor),
            onTap: () => _navigateToEditProfile(context),
          ),
          Divider(color: isDark ? Colors.white10 : Colors.grey.shade200),


          ListTile(
            leading: Icon(Icons.card_giftcard_rounded, color: isDark ? Colors.blue[300] : const Color(0xFF0D47A1)),
            title: Text('Giving', style: TextStyle(fontWeight: FontWeight.w500, color: mainTextColor)),
            trailing: Icon(Icons.chevron_right_rounded, color: subTextColor),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GivingScreen())
              );
            },
          ),
          Divider(color: isDark ? Colors.white10 : Colors.grey.shade200),

          ListTile(
            leading: Icon(Icons.church_rounded, color: isDark ? Colors.blue[300] : const Color(0xFF0D47A1)),
            title: Text('Cathedral Project Summary', style: TextStyle(fontWeight: FontWeight.w500, color: mainTextColor)),
            trailing: Icon(Icons.chevron_right_rounded, color: subTextColor),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Project Summary placeholder')),
              );
            },
          ),
          Divider(color: isDark ? Colors.white10 : Colors.grey.shade200),

          // 4. Clear Local Cache Map
          ListTile(
            leading: Icon(Icons.storage_rounded, color: isDark ? Colors.blue[300] : const Color(0xFF0D47A1)),
            title: Text('Clear Local Cache Map', style: TextStyle(fontWeight: FontWeight.w500, color: mainTextColor)),
            trailing: Icon(Icons.chevron_right_rounded, color: subTextColor),
            onTap: () async {
              // 1. Show processing state
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Processing cache clearance...'), duration: Duration(seconds: 1)),
              );

              // 2. Clear Temporary App Cache (Files/Images)
              try {
                final tempDir = await getTemporaryDirectory();
                if (tempDir.existsSync()) {
                  tempDir.deleteSync(recursive: true);
                }
              } catch (e) {
                debugPrint("🚨 Error clearing temp directory: $e");
              }

              final prefs = await SharedPreferences.getInstance();
              final Set<String> allKeys = prefs.getKeys();
              final List<String> identityKeys = [
                'isLoggedIn',
                'appActiveUserId',
                'appActiveUserLabel',
                'userId',
                'userName',
                'userEmail',
                'activeStaffId',
                'isStaffRegistered',
                'appThemeMode',
              ];

              int clearedCount = 0;
              for (String key in allKeys) {
                if (!identityKeys.contains(key) && !key.startsWith('user_avatar_path_')) {
                  await prefs.remove(key);
                  clearedCount++;
                }
              }

              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🗑️ App cache wiped. Session ID (#${SessionManager.currentUserId}) preserved.'),
                  backgroundColor: Colors.greenAccent.shade700,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          Divider(color: isDark ? Colors.white10 : Colors.grey.shade200),

          // 5. About Trial Build
          ListTile(
            leading: Icon(Icons.info_outline_rounded, color: isDark ? Colors.blue[300] : const Color(0xFF0D47A1)),
            title: Text('About Trial Build', style: TextStyle(fontWeight: FontWeight.w500, color: mainTextColor)),
            trailing: Icon(Icons.chevron_right_rounded, color: subTextColor),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutTrialBuildScreen()));
            },
          ),
          const SizedBox(height: 32),

          // 6. Logout Button
          ElevatedButton.icon(
            onPressed: () => _showLogoutConfirmationDialog(context, isDark, cardBackground, mainTextColor),
            icon: const Icon(Icons.logout_rounded, size: 20, color: Colors.white),
            label: const Text('Logout from App', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}