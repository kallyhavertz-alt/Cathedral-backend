import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:math' as math;
import 'package:untitled/session_manager.dart';
import 'package:untitled/settings_screen.dart';
import 'package:untitled/local_database_helper.dart';

import 'create_post_modal.dart';
import 'event_details_screen.dart';
import 'feed_video_preview.dart';
import 'note_work_space_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Function(String newPath)? onAvatarUpdated;
  const ProfileScreen({Key? key, this.onAvatarUpdated}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _serverFullName = 'Cathedral Member';
  String _serverEmail = 'member@cathedral.org';
  String _serverLocation = '';
  String _serverBio = '';
  String _userName = 'Loading...';
  String _userEmail = '';
  bool _isSavingFile = false;
  String? _customImagePath;
  int _selectedTabIndex = 0;

  List<dynamic> _liveEvents = [];
  List<Map<String, dynamic>> _myUploadedPosts = [];
  List<Map<String, dynamic>> _userFavorites = [];
  List<Map<String, dynamic>> _feedPosts = [];
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

  String _selectedThemeFilter = 'ALL';

  String _formatBackendDate(String? isoString) {
    if (isoString == null) return '';
    try {
      DateTime parsed = DateTime.parse(isoString);
       return "${parsed.day}/${parsed.month}/${parsed.year}";
    } catch (e) {
      return '';
    }
  }
  // 💡 Ensure your local server url base matches your working setup:
// final String _communityBaseUrl = 'http://192.168.100.33:8080/api/v1/community';

  Future<void> _deleteMemberPost(dynamic postItem) async {
    final int? postId = postItem['id'] ?? postItem['postId'];
    final int activeMemberId = SessionManager.currentUserId;

    if (postId == null) return;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. Show Confirmation Sheet / Dialog Box
    bool confirmDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(dialogContext).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.delete_forever, color: Colors.redAccent, size: 26),
              SizedBox(width: 8),
              Text('Delete Post', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Are you sure you want to permanently delete this post from the community feed? This action cannot be undone.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'CANCEL',
                style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('DELETE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    ) ?? false;

    if (!confirmDelete) return;

    // 2. Fire the Network Call to Spring Boot
    final String deleteUrl = 'http://192.168.100.33:8080/api/v1/community/posts/$postId?memberId=$activeMemberId';

    try {
      final response = await http.delete(Uri.parse(deleteUrl)).timeout(const Duration(seconds: 7));

      if (response.statusCode == 200) {
        // 3. Update active UI State Array (Assumes your feed array is called _feedPosts or _memberPosts)
        setState(() {
          // Targets whichever tracking array is active on this view layout screen
          _feedPosts.removeWhere((element) => (element['id'] ?? element['postId']) == postId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Post successfully removed from community feed.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // Handles cases where the backend rejects it (e.g. memberId doesn't own the post)
        throw Exception("Server rejected action or permission denied.");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete post: ${e.toString().split('\n').first}'),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }


  Future<void> _loadUserProfileFromServer() async {
    try {
      final String targetUrl = 'http://192.168.100.33:8080/api/v1/community/user/${SessionManager.currentUserId}';
      final response = await http.get(Uri.parse(targetUrl));

      if (response.statusCode == 200) {

        final userData = json.decode(response.body);
        setState(() {
          _serverFullName = userData['fullName'] ?? 'Cathedral Member';
          _serverEmail = userData['email'] ?? 'member@cathedral.org';
          _serverLocation = userData['residentialCell'] ?? '';
          _serverBio = userData['bio'] ?? '';
          _serverAvatarPath = userData['profilePictureUrl'];
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

    final String postsUrl = 'http://192.168.100.33:8080/api/v1/community/posts/member?memberId=${SessionManager.currentUserId}';
    final String themesUrl = 'http://192.168.100.33:8080/api/v1/public/themes';

    try {
      final List<Map<String, dynamic>> localFavorites = await LocalDatabaseHelper.instance.getFavoritesForUser(SessionManager.currentUserId);

       final responses = await Future.wait([
        http.get(Uri.parse(postsUrl)),
        http.get(Uri.parse(themesUrl)),
      ]);

      final http.Response postsResponse = responses[0];
      final http.Response themesResponse = responses[1];

      setState(() {
        _userFavorites = localFavorites.map((fav) => Map<String, dynamic>.from(fav)).toList();

        if (postsResponse.statusCode == 200) {
          final List<dynamic> parsedPosts = json.decode(postsResponse.body);
          _myUploadedPosts = parsedPosts.map((post) => {
            'id': post['id'],
            'caption': post['caption'] ?? '',
            'mediaUrl': post['mediaUrl'] ?? '',
            'localMedia': null,
          }).toList();
        } else {
          debugPrint("🚨 Failed loading member posts: ${postsResponse.statusCode}");
        }

        if (themesResponse.statusCode == 200) {
          final List<dynamic> parsedThemes = json.decode(themesResponse.body);
          _liveEvents = parsedThemes;
        } else {
          debugPrint("🚨 Failed loading church themes: ${themesResponse.statusCode}");
        }
      });

    } catch (e) {
      print("🚨 Failed to connect to backend database endpoints: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingContent = false;
        });
      }
    }
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

  void _navigateToSettings() async {
    final bool? shouldRefresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          currentName: _serverFullName,
          currentEmail: _serverEmail,
          currentLocation: _serverLocation,
          currentBio: _serverBio,
          currentAvatarPath: _serverAvatarPath,
          onAvatarUpdated: widget.onAvatarUpdated,
        ),
      ),
    );
    if (shouldRefresh == true) {
      _loadUserProfileFromServer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mainTextColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white60 : Colors.grey[600]!;
    final Color cardBackground = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color viewportBg = isDark ? const Color(0xFF141414) : Colors.grey.shade50;
    final Color borderStrokeColor = isDark ? Colors.white12 : Colors.grey.shade200;

    final Color badgeBg = isDark ? const Color(0xFF1A2638) : Colors.blue.shade50;
    final Color badgeBorder = isDark ? Colors.blue.shade400.withValues(alpha: 0.2) : const Color(0xFF0D47A1).withValues(alpha: 0.3);
    final Color badgeText = isDark ? Colors.blue.shade300 : const Color(0xFF0D47A1);

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
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
                              if (_serverBio.trim().isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  _serverBio,
                                  style: TextStyle(fontSize: 14, color: mainTextColor, fontStyle: FontStyle.italic),
                                ),
                              ],
                              if (_serverLocation.trim().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.location_on_outlined, size: 14, color: subTextColor),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _serverLocation,
                                        style: TextStyle(fontSize: 13, color: subTextColor),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
                                  onPressed: _navigateToSettings,
                                ),
                                const SizedBox(width: 4),
                                Builder(builder: (buttonContext) {
                                  return IconButton(
                                    icon: Icon(Icons.menu, color: mainTextColor, size: 28),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      // 🎯 This now correctly finds the outer HomeScreen Scaffold
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
                                  child: CircleAvatar(
                                    radius: 40,
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
                      child: Text('ACK St. James Cathedral Member', style: TextStyle(color: badgeText, fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Activity Timeline',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                minHeight: 60.0,
                maxHeight: 60.0,
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      _buildActivityTabChip(label: 'Themes', index: 0, isDark: isDark),
                      const SizedBox(width: 8),
                      _buildActivityTabChip(label: 'Favourites', index: 1, isDark: isDark),
                      const SizedBox(width: 8),
                      _buildActivityTabChip(label: 'My Posts', index: 2, isDark: isDark),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: RefreshIndicator(
          onRefresh: () async {
            await _fetchActivityData();
            await _loadUserProfileFromServer();
          },
          color: const Color(0xFF0D47A1),
          child: Container(
            color: viewportBg,
            child: _buildDynamicActivityContent(isDark, mainTextColor, subTextColor),
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
        final List<dynamic> filteredThemes = _liveEvents.where((theme) {
          if (_selectedThemeFilter == 'ALL') return true;
          return (theme['themeType'] ?? '').toString().toUpperCase() == _selectedThemeFilter;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedThemeFilter,
                      icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.white70 : Colors.black87),
                      dropdownColor: Theme.of(context).cardColor,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ALL', child: Text('All Themes')),
                        DropdownMenuItem(value: 'WEEKLY', child: Text('Theme of the week')),
                        DropdownMenuItem(value: 'MONTHLY', child: Text('Theme of the Month')),
                        DropdownMenuItem(value: 'YEARLY', child: Text('Theme of the year')),
                      ],
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedThemeFilter = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: filteredThemes.isEmpty
                  ? Center(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_border_rounded, size: 54, color: isDark ? Colors.white24 : Colors.black12),
                      const SizedBox(height: 10),
                      Text(
                        _selectedThemeFilter == 'ALL'
                            ? 'No custom themes broadcasted yet.'
                            : 'No themes found matching this category.',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
                  : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemCount: filteredThemes.length,
                itemBuilder: (context, index) {
                  final theme = filteredThemes[index];

                   final String rawType = theme['themeType'] ?? 'WEEKLY';
                  final String reading = theme['reading'] ?? 'Scripture';
                  final String themeText = theme['themeText'] ?? '';
                  final String author = theme['postedByStaffName'] ?? 'Staff';
                  final String dateStr = _formatBackendDate(theme['createdAt']);

                  String displayTag = 'Theme of the week';
                  if (rawType == 'MONTHLY') displayTag = 'Theme of the Month';
                  if (rawType == 'YEARLY') displayTag = 'Theme of the year';

                  return GestureDetector(
                    onTap: () {

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EventDetailsScreen(themeData: theme, eventData: {},),
                            ),
                          );

                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: isDark ? Colors.white30 : Colors.black87),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              displayTag,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 📖 2. Reading Text Block
                          Text(
                            reading,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: mainText,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // 📜 3. Theme Subtitle Content Description
                          Text(
                            themeText,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: subText,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 👤 4. Metadata Footprint Row (Author & Date)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'by $author',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: subText.withValues(alpha: 0.8),
                                ),
                              ),
                              Text(
                                dateStr,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: subText.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );

      case 1:
        if (_userFavorites.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border_rounded, size: 54, color: isDark ? Colors.white24 : Colors.black12),
                  const SizedBox(height: 10),
                  const Text('Your favorited items will appear here.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
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
        if (_myUploadedPosts.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: 54, color: isDark ? Colors.white24 : Colors.black12),
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
            ),
          );
        }

        return Stack(
          children: [
            GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
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
                        borderRadius: BorderRadius.circular(8),
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
                        top: 4,
                        right: 4,
                        child: CircleAvatar(
                          backgroundColor: Colors.black.withValues(alpha: 0.4),
                          radius: 16,
                          child: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.white, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            iconSize: 16,
                            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                            onSelected: (value) {
                              if (value == 'delete') {
                                _deleteMemberPost(userPost);
                              }
                            },
                            itemBuilder: (BuildContext popupContext) => [
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                    SizedBox(width: 8),
                                    Text('Delete Post', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ],
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

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });
  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => math.max(maxHeight, minHeight);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}