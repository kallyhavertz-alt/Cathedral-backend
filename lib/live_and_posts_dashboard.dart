import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'community_models.dart';
import 'live_and_sermons_tab.dart';
import 'posts_tab.dart';

class LiveAndPostsDashboard extends StatefulWidget {
  final int currentMemberId;

  const LiveAndPostsDashboard({Key? key, required this.currentMemberId}) : super(key: key);

  @override
  State<LiveAndPostsDashboard> createState() => _LiveAndPostsDashboardState();
}

class _LiveAndPostsDashboardState extends State<LiveAndPostsDashboard> {
  bool _isLoading = true;
  VideoDashboardFeed? _mediaData;
  List<MemberPostModel> _communityFeed = [];

  final String _baseUrl = "http://192.168.100.33:8080/api/v1/community";

  @override
  void initState() {
    super.initState();
    _loadAllDashboardData();
  }

  Future<void> _loadAllDashboardData() async {
    setState(() => _isLoading = true);

    // 🟩 Step 1: Fire off both API requests concurrently
    final mediaFuture = http.get(Uri.parse('$_baseUrl/media-dashboard?memberId=${widget.currentMemberId}'));
    final feedFuture = http.get(Uri.parse('$_baseUrl/feed?memberId=${widget.currentMemberId}'));

    // Wait for both network responses safely
    final responses = await Future.wait([mediaFuture, feedFuture]).catchError((error) {
      print("🚨 Critical Network Connection Failure: $error");
      return <http.Response>[];
    });

    if (responses.length < 2) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to connect to church backend server.')),
      );
      return;
    }

    final mediaRes = responses[0];
    final feedRes = responses[1];

    VideoDashboardFeed? parsedMedia;
    List<MemberPostModel> parsedFeed = [];

    // 🟩 Step 2: Totally isolated parsing block for Media Dashboard Data
    try {
      if (mediaRes.statusCode == 200) {
        print("====== BACKEND MEDIA RESPONDED ======");
        print(mediaRes.body);
        print("=====================================");
        final Map<String, dynamic> mediaJson = json.decode(mediaRes.body);
        parsedMedia = VideoDashboardFeed.fromJson(mediaJson);
      } else {
        print("❌ Media endpoint responded with status code: ${mediaRes.statusCode}");
      }
    } catch (e) {
      print("🚨 Silent formatting mismatch inside community_models parsing for Media: $e");
    }

    // 🟩 Step 3: Totally isolated parsing block for Social Timeline Feed Data
    try {
      if (feedRes.statusCode == 200) {
        final List decodedFeed = json.decode(feedRes.body);
        parsedFeed = decodedFeed.map((item) => MemberPostModel.fromJson(item)).toList();
      } else {
        print("❌ Social feed endpoint responded with status code: ${feedRes.statusCode}");
      }
    } catch (e) {
      print("🚨 Silent formatting mismatch inside community_models parsing for Posts: $e");
    }

    // 🟩 Step 4: Commit state adjustments safely to the layout tree
    setState(() {
      _mediaData = parsedMedia;
      _communityFeed = parsedFeed;
      _isLoading = false;
    });
  }

  Future<void> _handleLikeToggle(int postId) async {
    try {
      final response = await http.post(Uri.parse('$_baseUrl/posts/$postId/like?memberId=${widget.currentMemberId}'));
      if (response.statusCode == 200) {
        final bool isLikedNow = json.decode(response.body);
        setState(() {
          final target = _communityFeed.firstWhere((p) => p.id == postId);
          target.isLikedByMe = isLikedNow;
          target.likesCount = isLikedNow ? target.likesCount + 1 : target.likesCount - 1;
        });
      }
    } catch (e) {
      print("Error toggling like status: $e");
    }
  }

  Future<void> _handleCommentSubmission(int postId, String text) async {
    try {
      final url = '$_baseUrl/posts/$postId/comment?memberId=${widget.currentMemberId}&content=${Uri.encodeComponent(text)}';
      final response = await http.post(Uri.parse(url));
      if (response.statusCode == 200) {
        _loadAllDashboardData();
      }
    } catch (e) {
      print("Error processing community comment: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Live & Fellowship', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            indicatorColor: Colors.amber,
            tabs: [
              Tab(text: "LIVE AND SERMONS"),
              Tab(text: "POSTS"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
          children: [
            // Tab 1 UI View panel
            _mediaData == null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Sermons dashboard details temporary unavailable.'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _loadAllDashboardData,
                    child: const Text('Try Reloading'),
                  )
                ],
              ),
            )
                : LiveAndSermonsTab(
              data: _mediaData!,
              onRefresh: _loadAllDashboardData,
            ),

            // Tab 2 UI View panel (Will render perfectly now even if Media drops!)
            PostsTab(
              initialFeed: _communityFeed,
              onLikeToggle: _handleLikeToggle,
              onAddComment: _handleCommentSubmission,
              onRefresh: _loadAllDashboardData,
            ),
          ],
        ),
      ),
    );
  }
}