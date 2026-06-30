import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mainTextColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white60 : Colors.grey.shade700;
    final Color cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50;
    final Color accentColor = isDark ? Colors.blue.shade300 : const Color(0xFF0D47A1);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: mainTextColor),
        title: Text('About Us', style: TextStyle(color: mainTextColor, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ⛪ CHURCH SECTION
            Row(
              children: [
                Icon(Icons.crib_sharp, color: accentColor, size: 28),
                const SizedBox(width: 10),
                Text('The ACK St James Cathedral', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: mainTextColor)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
              ),
              child: Text(
                'ACK St. James Cathedral is a spiritual home dedicated to growing a vibrant, Christ-centered congregation. Through fellowship, dynamic ministry, and continuous community outreach, we stand together as pillars of faith and transformation.',
                style: TextStyle(fontSize: 14, color: subTextColor, height: 1.5),
              ),
            ),
            const SizedBox(height: 28),

            // 💻 DEVELOPER SECTION
            Row(
              children: [
                Icon(Icons.code_rounded, color: accentColor, size: 28),
                const SizedBox(width: 10),
                Text('The Developer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: mainTextColor)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Engineered with Care',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: mainTextColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This application is custom-built using Flutter and Dart on a native Android Studio foundation.'
                        ' Backed by an optimized backend data layout architecture, the system is engineered to secure real-time '
                        'operational synchronization for parish members.For more queries or any bug encountered please don\'t forget to rate the the app according to your use experience'
                    ' Your Data here is secured and no way your personal credentials can be leaked because of using this application        . On important to add: The developer is a church member too and to confront him costs you nothing if you want to know more about the application.',

                    style: TextStyle(fontSize: 14, color: subTextColor, height: 1.5),
                  ),
                  Row(
                    children: [
                      Icon(Icons.code_rounded, color: accentColor, size: 28),
                      const SizedBox(width: 10),
                      Text('MEMBER', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: mainTextColor)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                    ),
                    child: Text('EVERY member using the app must be aware that any sensitive credential provided during account creation is protected and it'
                        ' cannot be used to do any dirty or malicious work. The declarations provided by the developer can be proved wrong or to be true only by querying him through the email: kallyhavertz@gmail.com',

                      style: TextStyle(fontSize: 14, color: Colors.redAccent, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}