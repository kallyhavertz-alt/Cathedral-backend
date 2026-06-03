// lib/session_manager.dart

class SessionManager {
  // 🔑 This is the global variable that holds the active user's ID.
  // default it to 1, but we can change it dynamically anytime!
  static int currentUserId = 1;

  // A quick helper to get the active user's name for your UI
  static String get currentUserLabel {
    return currentUserId == 1 ? "Harvard (User 1)" : "Test Friend (User 2)";
  }

  // Call this function to simulate switching profiles during your testing!
  static void switchUser(int newUserId) {
    currentUserId = newUserId;
  }
}