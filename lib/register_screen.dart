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

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator.adaptive()),
      );

      final url = Uri.parse('http://10.34.113.23:8080/api/users/register');

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
          // 🎯 DECODE THE GENERATED IDENTITY FROM POSTGRESQL
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          final dynamic rawId = responseData['id'];
          if (rawId == null) {
            throw Exception("The server saved the user but forgot to send back the 'id' key!");
          }
          final int registeredId = int.parse(responseData['id'].toString());
          print('🔑 SUCCESS: Lock SessionManager to unique User ID: $registeredId');

          SessionManager.currentUserId = registeredId;

          // 🎯 SECURE DATA ISOLATION: Lock session to this new ID instantly!
          SessionManager.currentUserId = registeredId;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setInt('userId', registeredId);
          await prefs.setString('userName', name);
          await prefs.setString('userEmail', email);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account successfully created!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate cleanly to the dashboard dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
              //  (route) => false,
          );

        } else {
          // Handle registration rejections cleanly
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

        // Clean up navigation safely if a connection drops out mid-process
        try {
          Navigator.pop(context);
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lost connection to server. Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Join St. James Cathedral',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Register to access dynamic events and project tracking.'),
              const SizedBox(height: 32),

              // Full Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),

              // Email Address Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => !value!.contains('@') ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 16),

              // Residential Cell Dropdown Menu
              DropdownButtonFormField<String>(
                value: _selectedcellgroup,
                hint: const Text('Select your residential group'),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.group_sharp),
                  border: OutlineInputBorder(),
                ),
                items: _residentialcellgroup.map((group) {
                  return DropdownMenuItem(value: group, child: Text(group));
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
                value: _selectedFellowship,
                hint: const Text('Select your Fellowship Group'),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.groups),
                  border: OutlineInputBorder(),
                ),
                items: _fellowshipGroups.map((group) {
                  return DropdownMenuItem(value: group, child: Text(group));
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
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.length < 6 ? 'Password must be 6+ chars' : null,
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _submitRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Sign Up', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}