import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    try {
      // 1. Check if we have internet before attempting network-bound Firebase calls
      final List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        print("📡 Offline: Skipping Firebase Messaging token registration.");
        return;
      }

      // 2. Request Permissions
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ FCM Permission granted');

        // 3. Get Token and Subscribe - these can hang or fail if network is flaky
        String? token = await _messaging.getToken().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print("⏳ FCM Token fetch timed out.");
            return null;
          },
        );

        if (token != null) {
          print("FCM TOKEN: $token");
        }

        await _messaging.subscribeToTopic('church_updates').timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print("⏳ Topic subscription timed out.");
          },
        );
        print('🚀 Device successfully subscribed to church_updates.');
      } else {
        print('❌ Notifications denied by user');
      }
    } catch (e) {
      print("⚠️ NotificationService initialization error: $e");
    }
  }

  // 🔒 ROUTE 1: BIND DEVICE TO SECURE STAFF PORTAL CHANNEL
  Future<void> subscribeToStaffUpdates() async {
    try {
      final List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) return;

      await _messaging.subscribeToTopic('staff_updates').timeout(
        const Duration(seconds: 8),
        onTimeout: () => print("⏳ Staff subscription timed out."),
      );
      print('🟩 Device safely subscribed to [staff_updates].');
    } catch (e) {
      print("⚠️ Error subscribing to staff channel: $e");
    }
  }

  // 🚪 ROUTE 2: DROPPING DEVICE SELECTION UPON LOGOUT / OPT-OUT
  Future<void> unsubscribeFromStaffUpdates() async {
    try {
      final List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) return;

      await _messaging.unsubscribeFromTopic('staff_updates').timeout(
        const Duration(seconds: 8),
        onTimeout: () => print("⏳ Staff unsubscription timed out."),
      );
      print('🚪 Device successfully dropped [staff_updates] subscription.');
    } catch (e) {
      print("⚠️ Error unsubscribing from staff channel: $e");
    }
  }
}