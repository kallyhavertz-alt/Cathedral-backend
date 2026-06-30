import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:untitled/main.dart';
import 'package:untitled/session_manager.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers to grab what the user types
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Dropdown value tracking
  String? _selectedFellowship;
  String? _selectedcellgroup;

  // Mock list of ACK St. James Fellowship/Cell Groups
  final List<String> _fellowshipGroups = [
    'The Eagles Link Chapel',
    'Teens Ministry',
    'Mother\'s Union',
    'Kenya Anglican Men\'s Association (KAMA)',
    'Cathedral Choir',
    'St. James Pillars (Clergy)',
  ];

  final List<String> _residentialcellgroup = [
    'Kirigiti',
    'Beersheba',
    'Ndumberi',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitRegistration() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final group = _selectedFellowship;
      final cellgroup = _selectedcellgroup;

      final bool isDark = Theme.of(context).brightness == Brightness.dark;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator.adaptive(
            valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.blue.shade300 : const Color(0xFF0D47A1)),
          ),
        ),
      );

      final url = Uri.parse('http://192.168.100.33:8080/api/users/register');

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'fullName': name,
            'email': email,
            'password': password,
            'fellowshipGroup': group,
            'residentialCell': cellgroup,
          }),
        ).timeout(const Duration(seconds: 10));
        print('📡 Server Response Received! Status Code: ${response.statusCode}');
        print('📡 RAW PAYLOAD FROM BACKEND: ${response.body}');

        if (!mounted) return;

        // 🛡️ Safe context dismissal of loading dialog
        Navigator.of(context, rootNavigator: true).pop();

        if (response.statusCode == 200 || response.statusCode == 201) {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          final dynamic rawId = responseData['id'];
          if (rawId == null) {
            throw Exception("The server saved the user but forgot to send back the 'id' key!");
          }
          final int registeredId = int.parse(responseData['id'].toString());
          print('🔑 SUCCESS: Lock SessionManager to unique User ID: $registeredId');

          // 🛡️ LOCK SESSION: Use centralized manager to ensure disk persistence matches memory state
          await SessionManager.saveUserSession(registeredId, name);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userName', name);
          await prefs.setString('userEmail', email);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account successfully created! WELCOME TO CATHEDRAL!!'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );

        } else {
          final responseData = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Registration failed.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        print('Fatal network intercept error: $e');
        if (!mounted) return;

        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No internet connection, request unreachable'),
            backgroundColor: Colors.black38,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🎨 ACTIVE SYSTEM MODE DETECTION MATRICES
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color mainTextColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white60 : Colors.grey.shade700;
    final Color inputFieldBg = isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50;
    final Color borderStrokeColor = isDark ? Colors.white24 : Colors.grey.shade400;
    final Color accentFocusColor = isDark ? Colors.blue.shade300 : const Color(0xFF0D47A1);

    // Explicit structural decoration config for code reuse
    InputDecoration inputThemeDecoration({required String label, required Widget prefixIcon, String? hintText}) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700),
        hintText: hintText,
        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400),
        prefixIcon: IconTheme(
          data: IconThemeData(color: isDark ? Colors.blue.shade300 : const Color(0xFF0D47A1)),
          child: prefixIcon,
        ),
        filled: true,
        fillColor: inputFieldBg,
        counterStyle: TextStyle(color: subTextColor),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderStrokeColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderStrokeColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentFocusColor, width: 1.5),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: mainTextColor),
        title: Text(
          'Create Account',
          style: TextStyle(color: mainTextColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              Text(
                'Join St. James Cathedral',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: mainTextColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Register to access dynamic events and project tracking.',
                style: TextStyle(fontSize: 14, color: subTextColor),
              ),
              const SizedBox(height: 32),

              // Full Name Field
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: mainTextColor, fontSize: 15),
                decoration: inputThemeDecoration(
                  label: 'Full Name',
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),

              // Email Address Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: mainTextColor, fontSize: 15),
                decoration: inputThemeDecoration(
                  label: 'Email Address',
                  prefixIcon: const Icon(Icons.email),
                ),
                validator: (value) => !value!.contains('@') ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 16),

              // Residential Cell Dropdown Menu
              DropdownButtonFormField<String>(
                initialValue: _selectedcellgroup,
                dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                style: TextStyle(color: mainTextColor, fontSize: 15),
                hint: Text('Select your residential group', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade600, fontSize: 14)),
                decoration: inputThemeDecoration(
                  label: 'Residential Cell',
                  prefixIcon: const Icon(Icons.group_sharp),
                ),
                items: _residentialcellgroup.map((group) {
                  return DropdownMenuItem(
                    value: group,
                    child: Text(group, style: TextStyle(color: mainTextColor)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedcellgroup = value;
                  });
                },
                validator: (value) => value == null ? 'Please select your residential group' : null,
              ),
              const SizedBox(height: 16),

              // Fellowship Dropdown Menu
              DropdownButtonFormField<String>(
                initialValue: _selectedFellowship,
                dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                style: TextStyle(color: mainTextColor, fontSize: 15),
                hint: Text('Select your Fellowship Group', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade600, fontSize: 14)),
                decoration: inputThemeDecoration(
                  label: 'Fellowship Group',
                  prefixIcon: const Icon(Icons.groups),
                ),
                items: _fellowshipGroups.map((group) {
                  return DropdownMenuItem(
                    value: group,
                    child: Text(group, style: TextStyle(color: mainTextColor)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFellowship = value;
                  });
                },
                validator: (value) => value == null ? 'Please select a group' : null,
              ),
              const SizedBox(height: 16),

              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                style: TextStyle(color: mainTextColor, fontSize: 15),
                decoration: inputThemeDecoration(
                  label: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                ),
                validator: (value) => value!.length < 6 ? 'Password must be 6+ chars' : null,
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _submitRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.blue[700] : const Color(0xFF0D47A1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: isDark ? 0 : 2,
                ),
                child: const Text('Sign Up', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}