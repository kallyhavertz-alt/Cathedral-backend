// lib/session_manager.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class SessionManager {
  // 🔑 Default to -1 (Unauthenticated state).
  // If a data leak happens, it forces an error instead of corrupting User 1's records!
  static int currentUserId = -1;
  static String currentUserLabel = "Guest User";

  // 🛰️ NEW: Dedicated variables to track the independent Staff Portal Session
  static String? currentStaffId;
  static bool isStaffActive = false;

  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

  /// ⚙️ Core Engine Initialization: Run this inside main.dart BEFORE runApp()
  static Future<void> initializeEngine(SharedPreferences rootrefs) async {
    // 1. Restore Regular Member Session
    int savedId = rootrefs.getInt('appActiveUserId') ?? rootrefs.getInt('userId') ?? -1;
    
    // 🛡️ Migration check: if userId exists but appActiveUserId doesn't, migrate it
    if (savedId != -1 && rootrefs.getInt('appActiveUserId') == null) {
      await rootrefs.setInt('appActiveUserId', savedId);
    }
    
    currentUserId = savedId;
    currentUserLabel = rootrefs.getString('appActiveUserLabel') ?? (savedId == 1 ? "elias(user1)" : "machs (user 2)");
    print("🚀 SESSION ENGINE REBOOT: Loaded User ID ($currentUserId) [$currentUserLabel]");

    // 🔑 2. NEW: Restore Temporary Staff Portal Session Identity if present
    currentStaffId = rootrefs.getString('activeStaffId');
    isStaffActive = rootrefs.getBool('isStaffRegistered') ?? false;
    print("🛰️ STAFF LAYER REBOOT: Active Staff ID ($currentStaffId) | Verified Status: $isStaffActive");

    // 3. Restore Theme Choice
    final String savedTheme = rootrefs.getString('appThemeMode') ?? 'system';
    if (savedTheme == 'light') {
      themeNotifier.value = ThemeMode.light;
    } else if (savedTheme == 'dark') {
      themeNotifier.value = ThemeMode.dark;
    } else {
      themeNotifier.value = ThemeMode.system;
    }
    print("🚀 UNIFIED SESSION ENGINE READY: User ID ($currentUserId) [$currentUserLabel]");
  }


  /// 🔐 Call this when a regular member successfully logs in!
  static Future<void> saveUserSession(int id, String label) async {
    currentUserId = id;
    currentUserLabel = label;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('appActiveUserId', id);
    await prefs.setString('appActiveUserLabel', label);
    print("🔒 SESSION SECURED: Committed User $id ($label) to persistent disk.");
  }

  /// 🧼 Call this when a regular member logs out to clear local caches cleanly
  static Future<void> clearSession() async {
    currentUserId = -1;
    currentUserLabel = "Guest User";

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('appActiveUserId');
    await prefs.remove('appActiveUserLabel');
    print("🧼 SESSION PURGED: Cache removed successfully.");
  }


  /// 🔐 Call this when a staff member successfully authenticates in the portal.
  /// Sets their temporary session identity while keeping the generic member tracking separate.
  static Future<void> startStaffSession(String staffId) async {
    currentStaffId = staffId;
    isStaffActive = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('activeStaffId', staffId);
    await prefs.setBool('isStaffRegistered', true);
    print("🔒 STAFF SESSION INITIALIZED: Welcome Staff ID -> $staffId");
  }

  /// 🚪 Call this when a staff member logs out of their workspace space.
  /// Wipes out the staff configuration variables cleanly so another staff member can use
  /// the device, while completely preserving the main app user session.
  static Future<void> clearStaffSession() async {
    currentStaffId = null;
    isStaffActive = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('activeStaffId');
    await prefs.setBool('isStaffRegistered', false);
    print("🧹 STAFF SESSION TERMINATED: Device reverted to standard member view mode safely.");
  }


  /// Persists user theme choice straight to device hardware storage
  static Future<void> updateTheme(ThemeMode mode) async {
    themeNotifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appThemeMode', mode.name);
  }
}

class AppSessionPalette {
  // A curated list of rich, premium church-themed background colors
  static final List<Color> _avatarColorsPool = [
    const Color(0xFF0D47A1), // Cathedral Deep Blue
    const Color(0xFF1B5E20), // Liturgical Green
    const Color(0xFF4A148C), // Royal Bishop Purple
    const Color(0xFFB71C1C), // Deep Velvet Red
    const Color(0xFFE65100), // Premium Amber Notice
    const Color(0xFF006064), // Deep Teal
    const Color(0xFF37474F), // Elegant Blue-Grey
  ];

  // This will hold the single chosen color for the entire runtime session
  static late final Color activeSessionColor;

  static void initializeSessionColor() {
    final random = Random();
    activeSessionColor = _avatarColorsPool[random.nextInt(_avatarColorsPool.length)];
    print("🎨 SESSION INITIALIZED: Selected Avatar Background Color: $activeSessionColor");
  }
}