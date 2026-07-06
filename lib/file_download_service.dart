import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';

class FileDownloadService {
  /// 🚀 Downloads a file and shows progress at the bottom of the screen.
  /// Once done, it saves the file and triggers the native share sheet.
  static Future<void> downloadAndShare(BuildContext context, String url, String fileName) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final progressNotifier = ValueNotifier<double>(0.0);
    bool isDone = false;

    // 🔽 1. SHOW BOTTOM PROGRESS BAR
    final snackBar = scaffoldMessenger.showSnackBar(
      SnackBar(
        duration: const Duration(hours: 1), // Keep it open until manually closed or done
        backgroundColor: Colors.grey[900],
        content: ValueListenableBuilder<double>(
          valueListenable: progressNotifier,
          builder: (context, value, child) {
            return Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDone ? "✅ Download Complete!" : "📥 Downloading ${fileName}...",
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: value,
                        backgroundColor: Colors.white10,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Text(
                  "${(value * 100).toStringAsFixed(0)}%",
                  style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            );
          },
        ),
      ),
    );

    try {
      final client = http.Client();
      final response = await client.send(http.Request('GET', Uri.parse(url)));
      
      if (response.statusCode != 200) throw Exception('Server error: ${response.statusCode}');

      final total = response.contentLength ?? 0;
      int received = 0;
      final List<int> bytes = [];

      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        received += chunk.length;
        if (total > 0) {
          progressNotifier.value = received / total;
        }
      }

      isDone = true;
      progressNotifier.value = 1.0;
      
      // Give the user a moment to see 100%
      await Future.delayed(const Duration(milliseconds: 500));
      scaffoldMessenger.hideCurrentSnackBar();

      // 💾 2. SAVE TO DISK
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      // 🕊️ 3. TRIGGER SHARE
      final xFile = XFile(file.path);
      await Share.shareXFiles([xFile], text: 'Shared from ACK St. James Cathedral App');

    } catch (e) {
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("🚨 Download failed: $e"), backgroundColor: Colors.redAccent),
      );
      debugPrint("Download Error: $e");
    } finally {
      progressNotifier.dispose();
    }
  }

  // Backwards compatibility for old method name if used elsewhere
  static Future<void> downloadWithProgress(BuildContext context, String url, String fileName) async {
     return downloadAndShare(context, url, fileName);
  }
}
