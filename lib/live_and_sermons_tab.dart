import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'community_models.dart';
import 'fullscreen_video_player.dart';
import 'feed_video_preview.dart';
import 'package:share_plus/share_plus.dart';
import 'file_download_service.dart';
import 'shorts_reel_screen.dart';
import 'deep_link_service.dart';

class LiveAndSermonsTab extends StatefulWidget {
  final VideoDashboardFeed data;
  final VoidCallback onRefresh;

  const LiveAndSermonsTab({
    Key? key,
    required this.data,
    required this.onRefresh
  }) : super(key: key);

  @override
  State<LiveAndSermonsTab> createState() => _LiveAndSermonsTabState();
}

class _LiveAndSermonsTabState extends State<LiveAndSermonsTab> {
  List<CathedralVideoModel> _localLiveStreams = [];
  List<dynamic> _localPastServices = [];

  @override
  void initState() {
    super.initState();
    _processMediaTimeline();
  }

  @override
  void didUpdateWidget(covariant LiveAndSermonsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _processMediaTimeline();
    }
  }

  void _processMediaTimeline() {
    final rawLive = List<CathedralVideoModel>.from(widget.data.activeLiveStreams);
    final rawPast = List<dynamic>.from(widget.data.pastServices);
    final List<CathedralVideoModel> finalizedLive = [];
    final List<dynamic> shiftedToPast = [];
    final now = DateTime.now();

    for (var video in rawLive) {
      bool isStillLive = true;
      try {
        DateTime? createdAt = DateTime.tryParse(video.createdAtStr);
        if (createdAt != null && now.isAfter(createdAt.add(const Duration(minutes: 120)))) {
          isStillLive = false;
        }
      } catch (_) {}
      if (isStillLive) finalizedLive.add(video); else shiftedToPast.add(video);
    }
    setState(() {
      _localLiveStreams = finalizedLive;
      _localPastServices = [...shiftedToPast, ...rawPast];
    });
  }

  void _showOptionsBottomSheet(BuildContext context, String title, String videoUrl, int? id) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.download, color: Colors.blue),
                title: const Text('Download Service Audio/Media', style: TextStyle(fontSize: 14, color: Colors.black87)),
                onTap: () {
                  Navigator.pop(context);
                  final String fileName = "Cathedral_Service_${DateTime.now().millisecondsSinceEpoch}.mp4";
                  if (!videoUrl.contains("youtube.com") && !videoUrl.contains("youtu.be")) {
                    FileDownloadService.downloadWithProgress(context, videoUrl, fileName);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('YouTube content can only be viewed online.')));
                  }
                },
              ),
              /*ListTile(
                leading: const Icon(Icons.share, color: Colors.green),
                title: const Text('Share Broadcast Link'),
                onTap: () {
                  Navigator.pop(context);
                  DeepLinkService.shareContent(
                    type: 'services', 
                    id: id?.toString() ?? '0', 
                    title: title,
                    description: "Watch our service: $title"
                  );
                },
              ),

               */
              ListTile(
                leading: const Icon(Icons.flag, color: Colors.red),
                title: const Text('Report Content Issue'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPastServiceCard(BuildContext context, dynamic pastSermon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(pastSermon.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(pastSermon.createdAtStr ?? 'Past Archive', style: const TextStyle(fontSize: 12)),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showOptionsBottomSheet(context, pastSermon.title, pastSermon.videoUrl, pastSermon.id),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullscreenVideoPlayer(videoUrl: pastSermon.videoUrl, title: pastSermon.title))),
            child: Container(
              height: 160,
              width: double.infinity,
              color: Colors.black,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Builder(
                    builder: (context) {
                      final String url = pastSermon.videoUrl;
                      final Match? match = RegExp(r'^.*(?:(?:youtu\.be\/|v\/|vi\/|u\/\w\/|embed\/|shorts\/|live\/)|(?:(?:watch)?\?v(?:i)?=|\&v(?:i)?=))([^#\&\?]*).*').firstMatch(url);
                      String? videoId = (match != null && match.groupCount >= 1) ? match.group(1) : null;
                      if (videoId != null && videoId.length == 11) {
                        return Image.network('https://img.youtube.com/vi/$videoId/hqdefault.jpg', fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (c, e, s) => Container(color: Colors.grey[900]));
                      }
                      return Container(color: Colors.grey[900]);
                    },
                  ),
                  Container(color: Colors.black26),
                  const Icon(Icons.play_circle_fill, size: 50, color: Colors.white70),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<MemberPostModel> allShorts = List<MemberPostModel>.from(widget.data.memberShortVideos);
    final List<CathedralVideoModel> liveStreams = _localLiveStreams;
    final List<dynamic> allServices = _localPastServices;

    List<Widget> timelineBlocks = [];
    int shortsIndex = 0;
    int servicesIndex = 0;

    while (shortsIndex < allShorts.length || servicesIndex < allServices.length) {
      if (shortsIndex < allShorts.length) {
        int endRange = math.min(shortsIndex + 11, allShorts.length);
        final currentShortsChunk = allShorts.sublist(shortsIndex, endRange);
        shortsIndex = endRange;

        timelineBlocks.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0), child: Text('Member Fellowship Shorts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, letterSpacing: 0.5))),
              const SizedBox(height: 8),
              SizedBox(
                height: 280, // 🟩 INCREASED HEIGHT for larger shorts
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: currentShortsChunk.length,
                  itemBuilder: (context, idx) {
                    final shortPost = currentShortsChunk[idx];
                    final String fullMediaUrl = shortPost.mediaUrl.startsWith('http') ? shortPost.mediaUrl : 'http://192.168.100.33:8080${shortPost.mediaUrl.startsWith('/') ? '' : '/'}${shortPost.mediaUrl}';
                    
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ShortsReelScreen(shorts: allShorts, initialIndex: allShorts.indexOf(shortPost)))),
                      child: Container(
                        width: 170, // 🟩 INCREASED WIDTH (Like Facebook/Reels style)
                        margin: const EdgeInsets.only(right: 12, bottom: 10, top: 4),
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          elevation: 5,
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: FeedVideoPreview(
                                  videoUrl: fullMediaUrl, 
                                  showControls: false, 
                                  autoPlay: true,
                                  muted: true, // 🟩 QUIET IN MAIN SCREEN
                                )
                              ),
                              // Subtle bottom gradient for name readability
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.4)],
                                      stops: const [0.7, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 10, left: 10, 
                                child: Row(
                                  children: [
                                    const CircleAvatar(radius: 10, backgroundColor: Colors.white24, child: Icon(Icons.person, size: 12, color: Colors.white)),
                                    const SizedBox(width: 6),
                                    Text(
                                      '@${shortPost.memberName}', 
                                      maxLines: 1, 
                                      overflow: TextOverflow.ellipsis, 
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                                    ),
                                  ],
                                )
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      }
      if (servicesIndex < allServices.length) {
        int endServiceRange = math.min(servicesIndex + 5, allServices.length);
        final currentServicesChunk = allServices.sublist(servicesIndex, endServiceRange);
        servicesIndex = endServiceRange;
        timelineBlocks.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(padding: EdgeInsets.symmetric(vertical: 4.0), child: Text('Past Services & Sermons', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
              const SizedBox(height: 6),
              ...currentServicesChunk.map((pastSermon) => _buildPastServiceCard(context, pastSermon)).toList(),
              const SizedBox(height: 18),
            ],
          ),
        );
      }
    }

    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (liveStreams.isNotEmpty) ...[
              Row(children: const [Icon(Icons.radio_button_checked, color: Colors.red, size: 18), SizedBox(width: 6), Text('Live Broadcasts Now', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 15))]),
              const SizedBox(height: 8),
              ...liveStreams.map((liveVideo) {
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullscreenVideoPlayer(videoUrl: liveVideo.videoUrl, title: liveVideo.title))),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 14.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Stack(
                      children: [
                        Container(
                          height: 190,
                          width: double.infinity,
                          color: Colors.black,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Builder(
                                builder: (context) {
                                  final String url = liveVideo.videoUrl;
                                  final Match? match = RegExp(r'^.*(?:(?:youtu\.be\/|v\/|vi\/|u\/\w\/|embed\/|shorts\/|live\/)|(?:(?:watch)?\?v(?:i)?=|\&v(?:i)?=))([^#\&\?]*).*').firstMatch(url);
                                  String? videoId = (match != null && match.groupCount >= 1) ? match.group(1) : null;
                                  if (videoId != null && videoId.length == 11) {
                                    return Image.network('https://img.youtube.com/vi/$videoId/hqdefault.jpg', fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (c, e, s) => Container(color: Colors.grey[900]));
                                  }
                                  return Container(color: Colors.grey[900]);
                                },
                              ),
                              Container(color: Colors.black26),
                              const Icon(Icons.play_circle_fill, size: 55, color: Colors.white70),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            color: Colors.black54,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(liveVideo.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: () => _showOptionsBottomSheet(context, liveVideo.title, liveVideo.videoUrl, liveVideo.id)),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 6),
            ],
            if (allShorts.isEmpty && allServices.isEmpty) const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40.0), child: Text('No media items available at this time.', style: TextStyle(color: Colors.grey)))) else ...timelineBlocks,
          ],
        ),
      ),
    );
  }
}
