import 'package:flutter/material.dart';
import 'package:untitled/rate_us_screen.dart';
import 'package:untitled/updates_screen.dart' hide SessionManager;
import 'package:untitled/session_manager.dart'; // 🎯 Import the theme notifier channel
import 'package:untitled/about_us_screen.dart';
class MoreOptionsDrawer extends StatelessWidget {
  const MoreOptionsDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🎨 Dynamically check background color state for text readability inside dialogs
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white, // Adapts seamlessly with active theme
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🏷️ Header title matching your red-accent "More" pen sketch
              const Text(
                'More',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 24),

              // 🏛️ Navigation Option Item Stack Loop
              _buildMenuRow(
                context: context,
                label: 'Change theme',
                icon: Icons.palette_outlined,
                onTap: () {
                  // 🌓 Open a sub-sheet to cleanly execute dynamic theme swapping selection
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    builder: (context) {
                      final Color textStyleColor = isDark ? Colors.white : Colors.black87;
                      return Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Appearance',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              leading: const Icon(Icons.wb_sunny_rounded, color: Colors.orange),
                              title: Text('Light Mode', style: TextStyle(color: textStyleColor)),
                              onTap: () {
                                SessionManager.updateTheme(ThemeMode.light);
                                Navigator.pop(context); // Close sheet
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.nightlight_round, color: Colors.blueGrey),
                              title: Text('Dark Mode', style: TextStyle(color: textStyleColor)),
                              onTap: () {
                                SessionManager.updateTheme(ThemeMode.dark);
                                Navigator.pop(context); // Close sheet
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.brightness_auto_rounded, color: Colors.purple),
                              title: Text('Match Phone Settings (System)', style: TextStyle(color: textStyleColor)),
                              onTap: () {
                                SessionManager.updateTheme(ThemeMode.system);
                                Navigator.pop(context); // Close sheet
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              _buildMenuRow(
                context: context,
                label: 'About us',
                icon: Icons.info_outline,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AboutUsScreen(),
                  ),
                  );
                  // TODO: Route to Cathedral History or Core Values presentation
                },
              ),
              _buildMenuRow(
                context: context,
                label: 'Updates',
                icon: Icons.browser_updated,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UpdatesScreen(key: UniqueKey()),
                    ),
                  );
                },
              ),
              _buildMenuRow(
                context: context,
                label: 'Rate us',
                icon: Icons.star_border_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RateUsScreen())
                  );
                  // TODO: Call Google Play Store review engine API links
                },
              ),

              // 🧱 Flexible Spacer pushes branding components cleanly to the baseline bottom margin
              const Spacer(),

              // 🛡️ Transparent ACK Church Branding Integration Layer
              Center(
                child: Column(
                  children: [
                    Container(
                      height: 100,
                      width: 100,
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                      child: Image.asset(
                        'assets/icim/background - Copy.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                              Icons.church,
                              size: 64,
                              color: isDark ? Colors.blue.shade300 : Colors.blue.shade900
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 🙏 Footnote text endorsement matching your handwriting exactly
                    Text(
                      'Your Church Always',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // 📑 Software Manifest Build Trace Key
                    const Text(
                      'Version 4.7.8+1',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Row option item helper method builder with Theme awareness injected
  Widget _buildMenuRow({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 6.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white: Colors.black87,
              ),
            ),
            Icon(icon, size: 20, color: isDark ? Colors.white60 : Colors.black54),
          ],
        ),
      ),
    );
  }
}