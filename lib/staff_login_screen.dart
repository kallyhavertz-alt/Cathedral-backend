import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'notification_service.dart';
import 'staff_workspace_screen.dart';
import 'session_manager.dart'; // 🚀 IMPORT THE UPGRADED SESSION MANAGER ENGINE

class StaffLoginScreen extends StatefulWidget {
  const StaffLoginScreen({Key? key}) : super(key: key);

  @override
  State<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends State<StaffLoginScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _loginIdController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();
  bool _isLoggingIn = false;

  // WIRED TO BACKEND
  void _executeStaffLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() {
      _isLoggingIn = true;
    });

    final Uri url = Uri.parse('http://192.168.100.33:8080/api/v1/staff/login');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'identity': _loginIdController.text.trim(),
          'password': _loginPasswordController.text,
        }),
      );

      print("📡 Login Server Response Status: ${response.statusCode}");
      print("📡 Login Response Body: ${response.body}");

      if (response.statusCode == 200) {
        // Parse the body response payload to extract who logged in
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        await SessionManager.clearStaffSession();

        final String authenticatedStaffId = (responseData['email'] ?? _loginIdController.text.trim()).toString();

        if (authenticatedStaffId.isEmpty || authenticatedStaffId == "null") {
           _showLoginSnackBar('Critical Error: Could not determine staff identity.');
           return;
        }

        // 🔒 SECURE CENTRAL SESSION: Instantly flag runtime and persistent storage keys
        await SessionManager.startStaffSession(authenticatedStaffId);

        await NotificationService().subscribeToStaffUpdates();
        print("successfully subscribed to staff updates");
        if (!mounted) return;

        // Push into the main workspace
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const StaffWorkspaceScreen()),
        );
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        _showLoginSnackBar(errorData['message'] ?? 'Invalid email/phone or password.');
      }
    } catch (e) {
      print("🚨 Login Exception Caught: $e");
      _showLoginSnackBar('Connection failed. Please ensure you are connected to the internet.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  void _showLoginSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _loginIdController.dispose();
    _loginPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = const Color(0xFF0D47A1);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Cathedral Staff Login',
          style: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _loginFormKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 185,
                    width: 185,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.transparent, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/icim/cathsign.jpg',
                        errorBuilder: (c, e, s) => Text(
                          'Asset Image Here',
                          style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'STAFF PORTAL',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.redAccent[700], letterSpacing: 1.2),
                  ),
                  Text(
                    'WELCOME BACK!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 1.1),
                  ),
                  const SizedBox(height: 28),

                  TextFormField(
                    controller: _loginIdController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email / Phone number',
                      prefixIcon: Icon(Icons.person_outline, color: primaryColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your email or phone number' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _loginPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Password required' : null,
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: _isLoggingIn ? null : _executeStaffLogin,
                      child: _isLoggingIn
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('Login.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 28),

                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13, height: 1.4),
                      children: [
                        const TextSpan(text: 'Staff access registration is configured exclusively inside the external '),
                        TextSpan(
                          text: 'Cathedral Portal Admin APK',
                          style: TextStyle(color: Colors.redAccent[700], fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}