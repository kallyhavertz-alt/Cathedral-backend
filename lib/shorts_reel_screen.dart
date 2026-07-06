import 'package:flutter/material.dart';
import 'community_models.dart';
import 'feed_video_preview.dart';

class ShortsReelScreen extends StatefulWidget {
  final List<MemberPostModel> shorts;
  final int initialIndex;

  const ShortsReelScreen({
    Key? key,
    required this.shorts,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<ShortsReelScreen> createState() => _ShortsReelScreenState();
}

class _ShortsReelScreenState extends State<ShortsReelScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        controller: _pageController,
        itemCount: widget.shorts.length,
        itemBuilder: (context, index) {
          final short = widget.shorts[index];
          final String fullMediaUrl = short.mediaUrl.startsWith('http')
              ? short.mediaUrl
              : 'http://192.168.100.33:8080${short.mediaUrl.startsWith('/') ? '' : '/'}${short.mediaUrl}';

          final String? avatarUrl = short.memberProfilePicUrl;
          final String fullAvatarUrl = avatarUrl == null || avatarUrl.isEmpty ? '' : (avatarUrl.startsWith('http')
              ? avatarUrl
              : 'http://192.168.100.33:8080${avatarUrl.startsWith('/') ? '' : '/'}$avatarUrl');

          return Stack(
            children: [
              // 🎥 VIDEO PLAYER
              Center(
                child: FeedVideoPreview(
                  videoUrl: fullMediaUrl, 
                  showControls: false, 
                  autoPlay: true,
                  muted: false, // 🔊 HAS SOUND IN REELS
                ),
              ),

              // 👤 MEMBER INFO OVERLAY
              Positioned(
                bottom: 40,
                left: 16,
                right: 50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white24,
                          backgroundImage: fullAvatarUrl.isNotEmpty ? NetworkImage(fullAvatarUrl) : null,
                          child: fullAvatarUrl.isEmpty 
                              ? const Icon(Icons.person, color: Colors.white, size: 24) 
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '@${short.memberName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            shadows: [Shadow(blurRadius: 5, color: Colors.black, offset: Offset(0, 2))],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      short.caption,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 14,
                        shadows: [Shadow(blurRadius: 5, color: Colors.black, offset: Offset(0, 2))],
                      ),
                    ),
                  ],
                ),
              ),

              // ❌ CLOSE BUTTON
              Positioned(
                top: 50,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              
              // 🏷️ REEL TAG
              Positioned(
                top: 50,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(10)),
                  child: const Text("REELS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
