import 'package:flutter/material.dart';
import 'package:untitled/updates_screen.dart';

class MoreOptionsDrawer extends StatelessWidget {
  const MoreOptionsDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
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
                label: 'Change theme',
                icon: Icons.palette_outlined,
                onTap: () {
                  // TODO: Wire up dynamic light/dark mode theme swapping execution
                },
              ),
              _buildMenuRow(
                label: 'About us',
                icon: Icons.info_outline, // Matches your box/info sketch indicator
                onTap: () {
                  // TODO: Route to Cathedral History or Core Values presentation
                },
              ),
              _buildMenuRow(
                label: 'Updates',
                icon: Icons.browser_updated, // Matches your update indicator sketch
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UpdatesScreen(key: UniqueKey()),
                    ),
                  );
                  // TODO: Check system update flags
                },
              ),
              _buildMenuRow(
                label: 'Rate us',
                icon: Icons.star_border_outlined, // Matches your triangle/star system mark
                onTap: () {
                  // TODO: Call Google Play Store review engine API links
                },
              ),

              // 🧱 Flexible Spacer pushes branding components cleanly to the baseline bottom margin
              const Spacer(),

              // 🛡️ Transparent ACK Church Branding Integration Layer
              Center(
                child: Column(
                  children: [
                    // Container wrapping your transparent image so it blends perfectly into the white canvas background
                    Container(
                      height: 100,
                      width: 100,
                      decoration: const BoxDecoration(
                        color: Colors.transparent, // Ensures it adopts seamlessly with background color
                      ),
                      child: Image.asset(
                        'assets/icim/background - Copy.png', // Add your asset file path here!
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Clean fallback placeholder box if image asset path isn't registered yet in pubspec.yaml
                          return Icon(Icons.church, size: 64, color: Colors.blue.shade900);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 🙏 Footnote text endorsement matching your handwriting exactly
                    const Text(
                      'Your Church Always',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                        color: Colors.black54,
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

  // Row option item helper method builder
  Widget _buildMenuRow(

      {required String label, required IconData icon, required VoidCallback onTap}) {
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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            Icon(icon, size: 20, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}