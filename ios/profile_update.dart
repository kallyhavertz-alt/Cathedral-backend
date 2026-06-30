/*
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/about_trial_build_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:untitled/welcome_screen.dart';
import 'package:untitled/session_manager.dart';

import 'create_post_modal.dart';
import 'feed_video_preview.dart';
import 'note_work_space_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Function(String newPath)? onAvatarUpdated;
  const ProfileScreen({Key? key, this.onAvatarUpdated}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Loading...';
  String _userEmail = '';
  String? _customImagePath;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSavingFile = false;

  // Track which activity tab is active (0 = Themes, 1 = Favourites, 2 = Posts)
  int _selectedTabIndex = 0;

  // Local Collections
  List<dynamic> _liveEvents = []; // Used for Themes tab items
  List<Map<String, dynamic>> _myUploadedPosts = []; // Empty by default to test empty state sketch layout
  List<Map<String, dynamic>> _userFavorites = [];
  bool _isLoadingContent = true;
  String? _serverAvatarPath; // Add this state variable at the top of your state class
  bool _isLoadingProfile = true;



  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchActivityData(); // 🟩 FIX: Turn off the loading state runner
    _loadUserProfileFromServer();
  }

  Future<void> _loadUserProfileFromServer() async {
    try {

      final String targetUrl = 'http://192.168.100.33:8080/api/v1/community/user/${SessionManager.currentUserId}';
      final response = await http.get(Uri.parse(targetUrl));

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        setState(() {
          // Grab the field path we created in the Spring Boot User entity
          _serverAvatarPath = userData['profilePictureUrl'];
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingProfile = false);
      debugPrint("🚨 Error loading user profile pic: $e");
    }
  }


  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String storageKey = 'user_avatar_path_${SessionManager.currentUserId}';
    setState(() {
      _userName = prefs.getString('userName') ?? 'Cathedral Member';
      _userEmail = prefs.getString('userEmail') ?? 'member@cathedral.org';
      _customImagePath = prefs.getString(storageKey);
    });
  }


  Future<void> _fetchActivityData() async {

    setState(() {
      _isLoadingContent = true;
    });

    try {
      final String targetUrl = 'http://192.168.100.33:8080/api/v1/community/posts/member?memberId=${SessionManager.currentUserId}';
      final response = await http.get(Uri.parse(targetUrl));

      if (response.statusCode == 200) {
        print("🎯 RAW BACKEND JSON PAYLOAD: ${response.body}");
        final List<dynamic> parsedList = json.decode(response.body);

        setState(() {

          _myUploadedPosts = parsedList.map((post) => {
            'id': post['id'],
            'caption': post['caption'] ?? '',

            'mediaUrl': post['mediaUrl'] ?? '',
            'localMedia': null,
          }).toList();
        });
      } else {
        print("🚨 Backend returned non-200 status code: ${response.statusCode}");
      }
    } catch (e) {
      print("🚨 Failed to connect to backend database table view: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingContent = false;
        });
      }
    }
  }


  Future<void> _pickAndSaveImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _isSavingFile = true);

      // 🛰️ 1. Prepare the MultiPart Request to Spring Boot
      final String targetUrl = 'http://192.168.100.33:8080/api/v1/community/member/${SessionManager.currentUserId}/profile-picture';
      final request = http.MultipartRequest('POST', Uri.parse(targetUrl));

      // Attach the selected image file
      request.files.add(
        await http.MultipartFile.fromPath('file', pickedFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // The server returns our new permanent web path url string
        final String uploadedServerPath = response.body;

        setState(() {
          // Update local state preview using the local file path instantly for snappy UI response
          _customImagePath = pickedFile.path;
          _serverAvatarPath = uploadedServerPath;
          _isSavingFile = false;
        });

        if (widget.onAvatarUpdated != null) {
          widget.onAvatarUpdated!(uploadedServerPath);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Profile photo synced to backend successfully!')),
        );
      } else {
        throw Exception("Backend rejected upload file path layout.");
      }
    } catch (e) {
      setState(() => _isSavingFile = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🚨 Failed to upload photo to church server.')),
      );
    }
  }

  /// 🧼 Clear profile configuration back to initial state defaults
  Future<void> _resetToDefaultAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final String storageKey = 'user_avatar_path_${SessionManager.currentUserId}';
    await prefs.remove(storageKey);

    setState(() {
      _customImagePath = null;
    });
  }

  /// 📱 Displays upload choices
  void _showMediaSourceSelectionModal(Color cardBg, Color mainText) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Update Profile Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: mainText),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF0D47A1)),
                title: Text('Choose from Gallery', style: TextStyle(color: mainText)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSaveImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF0D47A1)),
                title: Text('Take a New Photo', style: TextStyle(color: mainText)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSaveImage(ImageSource.camera);
                },
              ),
              if (_customImagePath != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  title: const Text('Remove Photo', style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(context);
                    _resetToDefaultAvatar();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // APPLICATION SETTINGS MODAL BOTTOM SHEET
  void _showSettingsModalBottomSheet(BuildContext context, bool isDark, Color mainText, Color subText, Color cardBg) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: cardBg,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Application Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: mainText),
              ),
              const SizedBox(height: 4),
              Text(
                'Device ID Isolation Node: Active (User #${SessionManager.currentUserId})',
                style: TextStyle(fontSize: 12, color: subText),
              ),
              Divider(height: 30, thickness: 1, color: isDark ? Colors.white12 : Colors.grey.shade300),
              ListTile(
                leading: Icon(Icons.sync_lock_rounded, color: isDark ? Colors.blue[300] : const Color(0xFF0D47A1)),
                title: Text('Force Database Re-Sync', style: TextStyle(fontWeight: FontWeight.w500, color: mainText)),
                trailing: Icon(Icons.chevron_right_rounded, color: subText),
                onTap: () async {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🗲 Cache fully re-synchronized!'),
                      backgroundColor: Colors.lightGreen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.storage_rounded, color: isDark ? Colors.blue[300] : const Color(0xFF0D47A1)),
                title: Text('Clear Local Cache Map', style: TextStyle(fontWeight: FontWeight.w500, color: mainText)),
                trailing: Icon(Icons.chevron_right_rounded, color: subText),
                onTap: () async {
                  Navigator.pop(context);
                  final prefs = await SharedPreferences.getInstance();
                  final String currentName = prefs.getString('userName') ?? 'Cathedral Member';
                  final String currentEmail = prefs.getString('userEmail') ?? 'member@cathedral.org';

                  await prefs.clear();
                  await prefs.setBool('isLoggedIn', true);
                  await prefs.setString('userName', currentName);
                  await prefs.setString('userEmail', currentEmail);

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🗑️ Local layout cache wiped successfully.'),
                      backgroundColor: Colors.greenAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.info_outline_rounded, color: isDark ? Colors.blue[300] : const Color(0xFF0D47A1)),
                title: Text('About Trial Build', style: TextStyle(fontWeight: FontWeight.w500, color: mainText)),
                trailing: Icon(Icons.chevron_right_rounded, color: subText),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutTrialBuildScreen()));
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // LOGOUT CONFIRMATION DIALOG
  void _showLogoutConfirmationDialog(BuildContext context, bool isDark, Color cardBg, Color mainText) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              const SizedBox(width: 10),
              Text('Log Out', style: TextStyle(color: mainText)),
            ],
          ),
          content: Text('Are you sure you want to log out of your Cathedral account?',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('No, Stay', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', false);
                SessionManager.currentUserId = -1;

                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                      (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Yes, Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color mainTextColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white60 : Colors.grey[600]!;
    final Color cardBackground = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color viewportBg = isDark ? const Color(0xFF141414) : Colors.grey.shade50;
    final Color borderStrokeColor = isDark ? Colors.white12 : Colors.grey.shade200;
    final Color dividerLineColor = isDark ? Colors.white10 : Colors.black12;

    final Color badgeBg = isDark ? const Color(0xFF1A2638) : Colors.blue.shade50;
    final Color badgeBorder = isDark ? Colors.blue.shade400.withValues(alpha: 0.2) : const Color(0xFF0D47A1).withValues(alpha: 0.3);
    final Color badgeText = isDark ? Colors.blue.shade300 : const Color(0xFF0D47A1);



    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userName,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: mainTextColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _userEmail,
                          style: TextStyle(fontSize: 14, color: subTextColor),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.settings, color: isDark ? Colors.white70 : Colors.black54, size: 26),
                            onPressed: () => _showSettingsModalBottomSheet(
                                context, isDark, mainTextColor, subTextColor, cardBackground),
                          ),
                          const SizedBox(width: 4),
                          Builder(builder: (buttonContext) {
                            return IconButton(
                              icon: Icon(Icons.menu, color: mainTextColor, size: 28),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                Scaffold.of(buttonContext).openEndDrawer();
                              },
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: borderStrokeColor, width: 1.5),
                            ),
                            child: CircleAvatar(radius: 50, // Big profile style size
                              backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],

                              // 🟩 The Display Priority Pipeline:
                              backgroundImage: _customImagePath != null
                                  ? FileImage(File(_customImagePath!)) as ImageProvider
                                  : (_serverAvatarPath != null && _serverAvatarPath!.isNotEmpty)
                                  ? NetworkImage('http://192.168.100.33:8080$_serverAvatarPath')
                                  : null,

                                child: (_customImagePath == null && (_serverAvatarPath == null || _serverAvatarPath!.isEmpty))
                                    ? Icon(Icons.person, size: 50, color: Colors.grey[600])
                                    : null,
                            ),
                          ),
                          if (_isSavingFile)
                            Positioned.fill(
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black45,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: -4,
                            right: -4,
                            child: GestureDetector(
                              onTap: _isSavingFile
                                  ? null
                                  : () => _showMediaSourceSelectionModal(cardBackground, mainTextColor),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D47A1),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                                ),
                                child: const Icon(Icons.edit, color: Colors.white, size: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeBorder),
                ),
                child: Text('ACK St. James Cathedral',
                    style: TextStyle(color: badgeText, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _showLogoutConfirmationDialog(context, isDark, cardBackground, mainTextColor),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderStrokeColor),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded, size: 20, color: Colors.redAccent),
                            SizedBox(width: 8),
                            Text('Logout from App',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Text(
                'Activity',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : Colors.black54),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildActivityTabChip(label: 'Themes', index: 0, isDark: isDark),
                  const SizedBox(width: 8),
                  _buildActivityTabChip(label: 'Favourites', index: 1, isDark: isDark),
                  const SizedBox(width: 8),
                  _buildActivityTabChip(label: 'Posts', index: 2, isDark: isDark),
                ],
              ),
              const SizedBox(height: 20),
              Divider(thickness: 1, color: dividerLineColor, height: 1),
              Expanded(
                child: Container(
                  color: viewportBg,
                  child: _buildDynamicActivityContent(isDark, mainTextColor, subTextColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityTabChip({required String label, required int index, required bool isDark}) {
    final bool isSelected = _selectedTabIndex == index;
    final Color selectedBg = isDark ? Colors.blue[700]! : const Color(0xFF0D47A1);
    final Color unselectedBg = isDark ? const Color(0xFF242424) : Colors.white;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? selectedBg : (isDark ? Colors.white10 : Colors.grey.shade300), width: 1.2),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
              fontWeight: FontWeight.bold,
              fontSize: 13),
        ),
      ),
    );
  }

  void _triggerCreatePostSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => CreatePostModal(
        currentMemberId: SessionManager.currentUserId,
        onPostSuccess: (String? localImagePath) {

          _fetchActivityData();
        },
      ),
    );
  }

  Widget _buildDynamicActivityContent(bool isDark, Color mainText, Color subText) {
    if (_isLoadingContent) {
      return Center(
        child: CircularProgressIndicator(color: isDark ? Colors.blue[400] : const Color(0xFF0D47A1)),
      );
    }

    final Color trailingArrowColor = isDark ? Colors.white30 : Colors.black26;

    switch (_selectedTabIndex) {
    // 🟩 CASE 0: THEMES TAB VIEW
      case 0:
        if (_liveEvents.isEmpty) {
          return const Center(
              child: Text('No custom themes broadcasted for this period.', style: TextStyle(color: Colors.grey)));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: _liveEvents.length,
          itemBuilder: (context, index) {
            final theme = _liveEvents[index];
            return ListTile(
                leading: Icon(Icons.bookmark_added_rounded, color: isDark ? Colors.amber[300] : Colors.amber[800]),
                title: Text(theme['title'] ?? 'Weekly Theme', style: TextStyle(fontWeight: FontWeight.bold, color: mainText)),
                subtitle: Text(theme['duration'] ?? 'June 2026', style: TextStyle(color: subText)),
                trailing: Icon(Icons.wb_sunny_outlined, color: trailingArrowColor, size: 18));
          },
        );


      case 1:
        if (_userFavorites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border_rounded, size: 48, color: isDark ? Colors.white24 : Colors.black26),
                const SizedBox(height: 8),
                const Text('Your favorited items will appear here.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: _userFavorites.length,
          itemBuilder: (context, index) {
            final fav = _userFavorites[index];
            final String eventTitle = fav['eventTitle'] ?? 'Personal Note';
            final bool isPersonalNote = eventTitle == 'Personal Note' ||
                eventTitle == 'General Sermon Note' ||
                eventTitle == 'Cathedral Service';

            IconData typeIcon = isPersonalNote ? Icons.description_outlined : Icons.event_rounded;
            Color iconColor = isPersonalNote
                ? (isDark ? Colors.teal[300]! : Colors.teal)
                : (isDark ? Colors.blue[300]! : const Color(0xFF0D47A1));

            return ListTile(
              leading: Icon(typeIcon, color: iconColor),
              title: Text(fav['title'] ?? 'Untitled Note', style: TextStyle(fontWeight: FontWeight.bold, color: mainText)),
              subtitle: Text(eventTitle, style: TextStyle(color: subText, fontSize: 13)),
              trailing: const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NoteWorkspaceScreen(
                      noteId: fav['id'],
                      eventId: fav['eventId'] ?? 1,
                      eventTitle: eventTitle,
                      isEditing: true,
                      initialTitle: fav['title'] ?? '',
                      initialContent: fav['content'] ?? '',
                    ),
                  ),
                ).then((value) => _fetchActivityData());
              },
            );
          },
        );
      case 2:
        final bool hasNotPostedYet = _myUploadedPosts.isEmpty;

        if (hasNotPostedYet) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border_rounded, size: 54, color: isDark ? Colors.white24 : Colors.black26),
                const SizedBox(height: 10),
                InkWell(
                  onTap: _triggerCreatePostSheet,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? Colors.blue[400]! : const Color(0xFF0D47A1), width: 1.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Create your first post +',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.blue[300] : const Color(0xFF0D47A1),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            GridView.builder(
              padding: const EdgeInsets.all(12).copyWith(bottom: 80),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.6,
              ),
              itemCount: _myUploadedPosts.length,
              itemBuilder: (context, index) {
                final userPost = _myUploadedPosts[index];
                final String? localPath = userPost['localMedia'];
                final String? serverUrl = userPost['mediaUrl'];

                return Container(
                  decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 3)
                        )
                      ]
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [

                      localPath != null
                          ? Image.file(File(localPath), fit: BoxFit.cover)
                          : (serverUrl != null && serverUrl.isNotEmpty)
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(8), // Keeps the edges clean inside your grid card
                        child: FeedVideoPreview(
                          videoUrl: serverUrl.startsWith('http')
                              ? serverUrl
                              : 'http://192.168.100.33:8080${serverUrl.startsWith('/') ? '' : '/'}$serverUrl',
                        ),
                      )
                          : Container(
                        color: isDark ? Colors.grey[900] : Colors.grey[100],
                        child: Center(
                            child: Icon(Icons.article_outlined, color: subText, size: 28)
                        ),
                      ),

                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.1),
                                Colors.black.withValues(alpha: 0.75),
                              ],
                              stops: const [0.6, 0.8, 1.0],
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        bottom: 12,
                        left: 10,
                        right: 10,
                        child: Text(
                          (userPost['caption'] != null && userPost['caption'].toString().isNotEmpty)
                              ? userPost['caption']
                              : 'Fellowship Update 📢',
                          maxLines: 2,

                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              height: 1.3
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            Positioned(
              bottom: 16,
              left: 30,
              right: 30,
              child: SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _triggerCreatePostSheet,
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  label: const Text(
                    'Add a post +',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.blue[600] : const Color(0xFF0D47A1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    elevation: 4,
                  ),
                ),
              ),
            ),
          ],
        );

      default:
        return const SizedBox();
    }
  }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:untitled/session_manager.dart';
import 'package:untitled/settings_screen.dart';

import 'create_post_modal.dart';
import 'feed_video_preview.dart';
import 'note_work_space_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Function(String newPath)? onAvatarUpdated;
  const ProfileScreen({Key? key, this.onAvatarUpdated}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Loading...';
  String _userEmail = '';
  String? _customImagePath;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSavingFile = false;

  int _selectedTabIndex = 0;

  List<dynamic> _liveEvents = [];
  List<Map<String, dynamic>> _myUploadedPosts = [];
  List<Map<String, dynamic>> _userFavorites = [];
  bool _isLoadingContent = true;
  String? _serverAvatarPath;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchActivityData();
    _loadUserProfileFromServer();
  }

  Future<void> _loadUserProfileFromServer() async {
    try {
      final String targetUrl = 'http://192.168.100.33:8080/api/v1/community/user/${SessionManager.currentUserId}';
      final response = await http.get(Uri.parse(targetUrl));

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        setState(() {
          _serverAvatarPath = userData['profilePictureUrl'];
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingProfile = false);
      debugPrint("🚨 Error loading user profile pic: $e");
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String storageKey = 'user_avatar_path_${SessionManager.currentUserId}';
    setState(() {
      _userName = prefs.getString('userName') ?? 'Cathedral Member';
      _userEmail = prefs.getString('userEmail') ?? 'member@cathedral.org';
      _customImagePath = prefs.getString(storageKey);
    });
  }

  Future<void> _fetchActivityData() async {
    setState(() {
      _isLoadingContent = true;
    });

    try {
      final String targetUrl = 'http://192.168.100.33:8080/api/v1/community/posts/member?memberId=${SessionManager.currentUserId}';
      final response = await http.get(Uri.parse(targetUrl));

      if (response.statusCode == 200) {
        final List<dynamic> parsedList = json.decode(response.body);
        setState(() {
          _myUploadedPosts = parsedList.map((post) => {
            'id': post['id'],
            'caption': post['caption'] ?? '',
            'mediaUrl': post['mediaUrl'] ?? '',
            'localMedia': null,
          }).toList();
        });
      }
    } catch (e) {
      print("🚨 Failed to connect to backend database table view: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingContent = false;
        });
      }
    }
  }

  Future<void> _pickAndSaveImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _isSavingFile = true);

      final String targetUrl = 'http://192.168.100.33:8080/api/v1/community/member/${SessionManager.currentUserId}/profile-picture';
      final request = http.MultipartRequest('POST', Uri.parse(targetUrl));

      request.files.add(await http.MultipartFile.fromPath('file', pickedFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final String uploadedServerPath = response.body;

        setState(() {
          _customImagePath = pickedFile.path;
          _serverAvatarPath = uploadedServerPath;
          _isSavingFile = false;
        });

        if (widget.onAvatarUpdated != null) {
          widget.onAvatarUpdated!(uploadedServerPath);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Profile photo synced to backend successfully!')),
        );
      } else {
        throw Exception("Backend rejected upload file path layout.");
      }
    } catch (e) {
      setState(() => _isSavingFile = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🚨 Failed to upload photo to church server.')),
      );
    }
  }

  Future<void> _resetToDefaultAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final String storageKey = 'user_avatar_path_${SessionManager.currentUserId}';
    await prefs.remove(storageKey);
    setState(() => _customImagePath = null);
  }

  void _showMediaSourceSelectionModal(Color cardBg, Color mainText) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Update Profile Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: mainText)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF0D47A1)),
                title: Text('Choose from Gallery', style: TextStyle(color: mainText)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSaveImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF0D47A1)),
                title: Text('Take a New Photo', style: TextStyle(color: mainText)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSaveImage(ImageSource.camera);
                },
              ),
              if (_customImagePath != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  title: const Text('Remove Photo', style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(context);
                    _resetToDefaultAvatar();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _triggerCreatePostSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => CreatePostModal(
        currentMemberId: SessionManager.currentUserId,
        onPostSuccess: (String? localImagePath) {
          _fetchActivityData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mainTextColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white60 : Colors.grey[600]!;
    final Color cardBackground = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color viewportBg = isDark ? const Color(0xFF141414) : Colors.grey.shade50;
    final Color borderStrokeColor = isDark ? Colors.white12 : Colors.grey.shade200;
    final Color dividerLineColor = isDark ? Colors.white10 : Colors.black12;

    final Color badgeBg = isDark ? const Color(0xFF1A2638) : Colors.blue.shade50;
    final Color badgeBorder = isDark ? Colors.blue.shade400.withValues(alpha: 0.2) : const Color(0xFF0D47A1).withValues(alpha: 0.3);
    final Color badgeText = isDark ? Colors.blue.shade300 : const Color(0xFF0D47A1);

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_userName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: mainTextColor)),
                        const SizedBox(height: 4),
                        Text(_userEmail, style: TextStyle(fontSize: 14, color: subTextColor)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.settings, color: isDark ? Colors.white70 : Colors.black54, size: 26),
                            // 🟩 MODIFIED: Directly push to the new SettingsScreen page view setup
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SettingsScreen()),
                              ).then((_) => _loadUserData()); // Refresh if user data changed
                            },
                          ),
                          const SizedBox(width: 4),
                          Builder(builder: (buttonContext) {
                            return IconButton(
                              icon: Icon(Icons.menu, color: mainTextColor, size: 28),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => Scaffold.of(buttonContext).openEndDrawer(),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: borderStrokeColor, width: 1.5),
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                              backgroundImage: _customImagePath != null
                                  ? FileImage(File(_customImagePath!)) as ImageProvider
                                  : (_serverAvatarPath != null && _serverAvatarPath!.isNotEmpty)
                                  ? NetworkImage('http://192.168.100.33:8080$_serverAvatarPath')
                                  : null,
                              child: (_customImagePath == null && (_serverAvatarPath == null || _serverAvatarPath!.isEmpty))
                                  ? Icon(Icons.person, size: 50, color: Colors.grey[600])
                                  : null,
                            ),
                          ),
                          if (_isSavingFile)
                            Positioned.fill(
                              child: Container(
                                decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                                child: const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: -4,
                            right: -4,
                            child: GestureDetector(
                              onTap: _isSavingFile ? null : () => _showMediaSourceSelectionModal(cardBackground, mainTextColor),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D47A1),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                                ),
                                child: const Icon(Icons.edit, color: Colors.white, size: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeBorder),
                ),
                child: Text('ACK St. James Cathedral', style: TextStyle(color: badgeText, fontWeight: FontWeight.w600, fontSize: 13)),
              ),

              // 🟩 REMOVED: Standalone logout container card completely gone to leave room for activity space
              const SizedBox(height: 20),

              Text(
                'Activity',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : Colors.black54),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildActivityTabChip(label: 'Themes', index: 0, isDark: isDark),
                  const SizedBox(width: 8),
                  _buildActivityTabChip(label: 'Favourites', index: 1, isDark: isDark),
                  const SizedBox(width: 8),
                  _buildActivityTabChip(label: 'Posts', index: 2, isDark: isDark),
                ],
              ),
              const SizedBox(height: 20),
              Divider(thickness: 1, color: dividerLineColor, height: 1),
              Expanded(
                child: Container(
                  color: viewportBg,
                  child: _buildDynamicActivityContent(isDark, mainTextColor, subTextColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityTabChip({required String label, required int index, required bool isDark}) {
    final bool isSelected = _selectedTabIndex == index;
    final Color selectedBg = isDark ? Colors.blue[700]! : const Color(0xFF0D47A1);
    final Color unselectedBg = isDark ? const Color(0xFF242424) : Colors.white;

    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? selectedBg : (isDark ? Colors.white10 : Colors.grey.shade300), width: 1.2),
        ),
        child: Text(
          label,
          style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87), fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildDynamicActivityContent(bool isDark, Color mainText, Color subText) {
    if (_isLoadingContent) {
      return Center(child: CircularProgressIndicator(color: isDark ? Colors.blue[400] : const Color(0xFF0D47A1)));
    }

    final Color trailingArrowColor = isDark ? Colors.white30 : Colors.black26;

    switch (_selectedTabIndex) {
      case 0:
        if (_liveEvents.isEmpty) {
          return const Center(child: Text('No custom themes broadcasted for this period.', style: TextStyle(color: Colors.grey)));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: _liveEvents.length,
          itemBuilder: (context, index) {
            final theme = _liveEvents[index];
            return ListTile(
              leading: Icon(Icons.bookmark_added_rounded, color: isDark ? Colors.amber[300] : Colors.amber[800]),
              title: Text(theme['title'] ?? 'Weekly Theme', style: TextStyle(fontWeight: FontWeight.bold, color: mainText)),
              subtitle: Text(theme['duration'] ?? 'June 2026', style: TextStyle(color: subText)),
              trailing: Icon(Icons.wb_sunny_outlined, color: trailingArrowColor, size: 18),
            );
          },
        );

      case 1:
        if (_userFavorites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border_rounded, size: 48, color: isDark ? Colors.white24 : Colors.black26),
                const SizedBox(height: 8),
                const Text('Your favorited items will appear here.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: _userFavorites.length,
          itemBuilder: (context, index) {
            final fav = _userFavorites[index];
            final String eventTitle = fav['eventTitle'] ?? 'Personal Note';
            final bool isPersonalNote = eventTitle == 'Personal Note' || eventTitle == 'General Sermon Note' || eventTitle == 'Cathedral Service';

            IconData typeIcon = isPersonalNote ? Icons.description_outlined : Icons.event_rounded;
            Color iconColor = isPersonalNote ? (isDark ? Colors.teal[300]! : Colors.teal) : (isDark ? Colors.blue[300]! : const Color(0xFF0D47A1));

            return ListTile(
              leading: Icon(typeIcon, color: iconColor),
              title: Text(fav['title'] ?? 'Untitled Note', style: TextStyle(fontWeight: FontWeight.bold, color: mainText)),
              subtitle: Text(eventTitle, style: TextStyle(color: subText, fontSize: 13)),
              trailing: const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NoteWorkspaceScreen(
                      noteId: fav['id'],
                      eventId: fav['eventId'] ?? 1,
                      eventTitle: eventTitle,
                      isEditing: true,
                      initialTitle: fav['title'] ?? '',
                      initialContent: fav['content'] ?? '',
                    ),
                  ),
                ).then((value) => _fetchActivityData());
              },
            );
          },
        );

      case 2:
        final bool hasNotPostedYet = _myUploadedPosts.isEmpty;
        if (hasNotPostedYet) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border_rounded, size: 54, color: isDark ? Colors.white24 : Colors.black26),
                const SizedBox(height: 10),
                InkWell(
                  onTap: _triggerCreatePostSheet,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? Colors.blue[400]! : const Color(0xFF0D47A1), width: 1.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Create your first post +',
                      style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.blue[300] : const Color(0xFF0D47A1), fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          );
        }




        return Stack(
          children: [
            GridView.builder(
              padding: const EdgeInsets.all(12).copyWith(bottom: 80),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.6,
              ),
              itemCount: _myUploadedPosts.length,
              itemBuilder: (context, index) {
                final userPost = _myUploadedPosts[index];
                final String? localPath = userPost['localMedia'];
                final String? serverUrl = userPost['mediaUrl'];

                return Container(
                  decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 3)
                        )
                      ]
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [

                      localPath != null
                          ? Image.file(File(localPath), fit: BoxFit.cover)
                          : (serverUrl != null && serverUrl.isNotEmpty)
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(8), // Keeps the edges clean inside your grid card
                        child: FeedVideoPreview(
                          videoUrl: serverUrl.startsWith('http')
                              ? serverUrl
                              : 'http://192.168.100.33:8080${serverUrl.startsWith('/') ? '' : '/'}$serverUrl',
                        ),
                      )
                          : Container(
                        color: isDark ? Colors.grey[900] : Colors.grey[100],
                        child: Center(
                            child: Icon(Icons.article_outlined, color: subText, size: 28)
                        ),
                      ),

                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.1),
                                Colors.black.withValues(alpha: 0.75),
                              ],
                              stops: const [0.6, 0.8, 1.0],
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        bottom: 12,
                        left: 10,
                        right: 10,
                        child: Text(
                          (userPost['caption'] != null && userPost['caption'].toString().isNotEmpty)
                              ? userPost['caption']
                              : 'Fellowship Update 📢',
                          maxLines: 2,

                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              height: 1.3
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            Positioned(
              bottom: 16,
              left: 30,
              right: 30,
              child: SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _triggerCreatePostSheet,
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  label: const Text(
                    'Add a post +',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.blue[600] : const Color(0xFF0D47A1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    elevation: 4,
                  ),
                ),
              ),
            ),
          ],
        );

      default:
        return const SizedBox();
    }
  }
}
///////////////////////////////////////////////////////////
radius: 50,
                                      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                                      backgroundImage: _customImagePath != null
                                          ? FileImage(File(_customImagePath!)) as ImageProvider
                                          : (_serverAvatarPath != null && _serverAvatarPath!.isNotEmpty)
                                          ? NetworkImage(_serverAvatarPath!.startsWith('http')
                                          ? _serverAvatarPath!
                                          : 'http://192.168.100.33:8080${_serverAvatarPath!.startsWith('/') ? '' : '/'}$_serverAvatarPath')
                                          : null,
                                      child: (_customImagePath == null && (_serverAvatarPath == null || _serverAvatarPath!.isEmpty))
                                          ? Icon(Icons.person, size: 50, color: Colors.grey[600])
                                          : null,


 */