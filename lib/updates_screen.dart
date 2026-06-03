import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// Import your session manager or wherever you store currentUserId
// import 'package:cathedral_app/session_manager.dart';

// Fake placeholder class to simulate your active session variables
class SessionManager {
  static int currentUserId = 1; // Fallback demo placeholder ID
}

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({Key? key}) : super(key: key);

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  bool _isInterestedChecked = false;
  bool _isCheckboxDisabled = false;
  bool _isLoading = false;

  // 📝 Text Controller to capture custom user view requests
  final TextEditingController _viewsController = TextEditingController();

  // 🎥 Mock Video Presentation States
  int _currentSlideIndex = 0;
  bool _isPlaying = true;
  double _videoProgress = 0.0;
  Timer? _slideTimer;
  Timer? _progressTimer;

  final List<Map<String, String>> _videoSlides = [
    {
      "title": "💳 Smooth M-Pesa Integration",
      "desc": "Direct Daraja API handshake ensures your tithes and cathedral building pledges update in real-time securely."
    },
    {
      "title": "📺 Live Stream Services",
      "desc": "Tap and tune into Sunday Main Sanctuary services directly from the app, wherever you are in Kenya."
    },
    {
      "title": "🔔 Real-Time Announcements",
      "desc": "Instant push notifications flash directly on your phone screen the moment church notice schedules are published."
    },
    {
      "title": "🏗️ The Grand Cathedral Tracker",
      "desc": "A fully audit-ready financial ledger tracking target milestones, monthly raised totals, and remaining goals."
    },
  ];

  @override
  void initState() {
    super.initState();
    _startMockVideoPlayback();
    _fetchCurrentSubmissionStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCurrentSubmissionStatus();
    });
  }
  Future<void> _fetchCurrentSubmissionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final int? savedUserId = prefs.getInt('userId');
    if (savedUserId != null) {
      SessionManager.currentUserId = savedUserId;
    }
    final int userId = SessionManager.currentUserId;
    print("📱 HARDWARE DIRECT CHECK: True active identity token -> $userId");
    print("📱 MOBILE DEPLOYMENT: Requesting status for ID token -> $userId");

    // 🧼 STEP 1: FORCE A PRISTINE RESET FOR THE NEW ACCOUNT
    setState(() {
      _isCheckboxDisabled = false;
      _isInterestedChecked = false;
      _viewsController.clear(); // 🎯 FIX: Wipes out the previous user's typed message!
    });

    final Uri url = Uri.parse('http://10.34.113.23:8080/api/v1/updates/check-status/$userId');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      print("📡 RAW INTERNET PAYLOAD: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['hasSubmitted'] == true) {
          // 🔒 LOCK SCREEN: This user has already submitted views
          setState(() {
            _isInterestedChecked = true;
            _isCheckboxDisabled = true;
            _viewsController.text = "Feedback successfully registered!";
          });
        } else {
          // 🔓 UNLOCK SCREEN: Fresh account, give them complete freedom to type!
          setState(() {
            _isInterestedChecked = false;
            _isCheckboxDisabled = false;
            _viewsController.clear();
          });
        }
      }
    } catch (e) {
      print("silent background check bypass: $e");
    }
  }
  @override
  void dispose() {
    _slideTimer?.cancel();
    _progressTimer?.cancel();
    _viewsController.dispose(); // 🧼 Prevent background memory leaks
    super.dispose();
  }

  void _startMockVideoPlayback() {
    _slideTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_isPlaying) {
        setState(() {
          _currentSlideIndex = (_currentSlideIndex + 1) % _videoSlides.length;
          _videoProgress = 0.0;
        });
      }
    });

    _progressTimer = Timer.periodic(const Duration(milliseconds: 90), (timer) {
      if (_isPlaying) {
        setState(() {
          if (_videoProgress < 1.0) {
            _videoProgress += 0.01;
          }
        });
      }
    });
  }

  void _togglePlayback() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  // 📡 THE LIVE BACKEND NETWORKING HUB
  Future<void> _submitUserInterest() async {
    final String userFeedback = _viewsController.text.trim();

    // 🛑 UI Validation check before hitting the server
    if (userFeedback.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add your feature views before marking interest!'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Replace with your laptop's actual development network IP address
    final int userId = SessionManager.currentUserId;
    final Uri url = Uri.parse('http://10.34.113.23:8080/api/v1/updates/register-interest/$userId');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'otherUpdate': userFeedback, // 🎯 Matches our Java DTO field exactly
        }),
      ).timeout(const Duration(seconds: 8));

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        // 🎉 SUCCESS HANDSHAKE CAUGHT
        setState(() {
          _isInterestedChecked = true;
          _isCheckboxDisabled = true; // Permanently lock inputs
          _viewsController.text = "Feedback successfully registered!";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(responseData['message'] ?? 'Interest logged!')),
              ],
            ),
            backgroundColor: const Color(0xFF0D47A1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // 🛑 SERVER REJECTION CAUGHT (Duplicates or Validation failure)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Failed to update configuration.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: Could not reach backend server ($e)'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSlide = _videoSlides[_currentSlideIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Updates',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Praise the Lord!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent),
              ),
              const SizedBox(height: 8),
              const Text(
                'Welcome Member, here is the section where you see the actual app to come.',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Text(
                'Our upcoming framework patch transforms how our congregation interfaces with building plans. Take an exclusive look at the operational timeline features engineered for the next release.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
              ),
              const SizedBox(height: 24),

              // 🎥 SIMULATED PLAYER CONTAINER
              const Text(
                'Update Features Video Preview:',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade900, const Color(0xFF0D47A1), Colors.black],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Stack(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Column(
                        key: ValueKey<int>(_currentSlideIndex),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            currentSlide["title"]!,
                            style: const TextStyle(color: Colors.amberAccent, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            currentSlide["desc"]!,
                            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _videoProgress,
                              minHeight: 4,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Preview Loop 00:0${_currentSlideIndex + 1} / 00:04",
                                style: const TextStyle(color: Colors.white60, fontSize: 11, fontFamily: 'monospace'),
                              ),
                              IconButton(
                                icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: Colors.white, size: 28),
                                onPressed: _togglePlayback,
                              )
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 📝 THE EXPLICIT CUSTOM USER VIEWS INPUT (79 Char Hard Max Limit)
              const Text(
                'Your Views on This Update:',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _viewsController,
                maxLength: 79, // 🔒 Native barrier locks typing at 79 chars max
                enabled: !_isCheckboxDisabled && !_isLoading,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: "What else should this update contain?",
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  filled: true,
                  fillColor: _isCheckboxDisabled ? Colors.grey.shade100 : Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // 🗳️ INDEPENDENT CHECKBOX AND LOGIC TRIGGER
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                decoration: BoxDecoration(
                  color: _isCheckboxDisabled ? Colors.green.shade50 : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _isLoading
                        ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0D47A1)),
                      ),
                    )
                        : Checkbox(
                      activeColor: Colors.green,
                      value: _isInterestedChecked,
                      onChanged: _isCheckboxDisabled
                          ? null
                          : (bool? value) {
                        if (value == true) {
                          _submitUserInterest();
                        }
                      },
                    ),
                    Expanded(
                      child: Text(
                        _isCheckboxDisabled
                            ? 'Your feedback has been committed to the server!'
                            : 'I agree that the update will have far reaching implication.',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _isCheckboxDisabled ? Colors.green.shade700 : Colors.black87
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 🙏 ENDORSEMENT BRANDING FOOTNOTE
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: const Text(
                  '"We are making Cathedral known together, take your part by supporting this!"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}