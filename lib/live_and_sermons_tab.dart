import 'package:flutter/material.dart';
import 'community_models.dart';
import 'fullscreen_video_player.dart';
import 'feed_video_preview.dart';

class LiveAndSermonsTab extends StatelessWidget {
  final VideoDashboardFeed data;
  final VoidCallback onRefresh;

  // 🟩 Clean constructor: No more messy raw liveVideos list
  const LiveAndSermonsTab({
    Key? key,
    required this.data,
    required this.onRefresh
  }) : super(key: key);

  void _showOptionsBottomSheet(BuildContext context, String title) {
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
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.green),
                title: const Text('Share Broadcast Link'),
                onTap: () => Navigator.pop(context),
              ),
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
  @override
  Widget build(BuildContext context) {
    print("DEBUG: Active Live Streams Count = ${data.activeLiveStreams.length}");
    if (data.activeLiveStreams.isNotEmpty) {
      print("DEBUG: First Live Video URL = ${data.activeLiveStreams.first.videoUrl}");
    }
    // 🟩 Extract our new type-safe list out of the verified data object
    final List<CathedralVideoModel> liveStreams = data.activeLiveStreams;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🛑 1. MULTIPLE LIVE NOW BANNER LOOPS
            if (liveStreams.isNotEmpty) ...[
              Row(
                children: const [
                  Icon(Icons.radio_button_checked, color: Colors.red, size: 18),
                  SizedBox(width: 6),
                  Text('Live Broadcasts Now', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 8),

              // 🟩 Dribbling around the single card constraint: Map every live stream to its own player item card!
              ...liveStreams.map((liveVideo) {
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullscreenVideoPlayer(
                        videoUrl: liveVideo.videoUrl,
                        title: liveVideo.title,
                      ),
                    ),
                  ),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 14.0), // Adds space between multiple live videos
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
                                  final RegExp regExp = RegExp(
                                    r'^.*(?:(?:youtu\.be\/|v\/|vi\/|u\/\w\/|embed\/|shorts\/|live\/)|(?:(?:watch)?\?v(?:i)?=|\&v(?:i)?=))([^#\&\?]*).*',
                                    caseSensitive: false,
                                  );
                                  final Match? match = regExp.firstMatch(url);
                                  String? videoId;
                                  if (match != null && match.groupCount >= 1) {
                                    videoId = match.group(1);
                                  }

                                  if (videoId != null && videoId.length == 11) {
                                    return Image.network(
                                      'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[900]),
                                    );
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
                                Expanded(
                                  child: Text(
                                      liveVideo.title,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.more_vert, color: Colors.white),
                                  onPressed: () => _showOptionsBottomSheet(context, liveVideo.title),
                                )
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 12),
            ],

            // MEMBER SHORTS SECTION
            const Text('Member Fellowship Shorts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            if (data.memberShortVideos.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No member clips shared today.', style: TextStyle(color: Colors.grey)),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.70,
                ),
                itemCount: data.memberShortVideos.length,
                itemBuilder: (context, index) {
                  final shortPost = data.memberShortVideos[index];
                  final String fullMediaUrl = shortPost.mediaUrl.startsWith('http')
                      ? shortPost.mediaUrl
                      : 'http://192.168.100.33:8080${shortPost.mediaUrl.startsWith('/') ? '' : '/'}${shortPost.mediaUrl}';
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: FeedVideoPreview(videoUrl: fullMediaUrl),
                        ),
                        Positioned(
                          top: 8, left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '@${shortPost.memberName}',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 24),

            // 📁 3. PAST SERMONS ARCHIVE
            const Text('Past Services & Sermons', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            if (data.pastServices.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No previous services posted yet.', style: TextStyle(color: Colors.grey)),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.pastServices.length,
                itemBuilder: (context, index) {
                  final pastSermon = data.pastServices[index];
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
                          subtitle: Text(pastSermon.createdAtStr, style: const TextStyle(fontSize: 12)),
                          trailing: IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () => _showOptionsBottomSheet(context, pastSermon.title),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => FullscreenVideoPlayer(videoUrl: pastSermon.videoUrl, title: pastSermon.title)),
                          ),
                          child: Container(
                            height: 160,
                            width: double.infinity,
                            color: Colors.black,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // 🟩 DYNAMIC YOUTUBE THUMBNAIL BACKGROUND ENGINE
                                Builder(
                                  builder: (context) {
                                    final String url = pastSermon.videoUrl;
                                    final RegExp regExp = RegExp(
                                      r'^.*(?:(?:youtu\.be\/|v\/|vi\/|u\/\w\/|embed\/|shorts\/|live\/)|(?:(?:watch)?\?v(?:i)?=|\&v(?:i)?=))([^#\&\?]*).*',
                                      caseSensitive: false,
                                    );
                                    final Match? match = regExp.firstMatch(url);
                                    String? videoId;
                                    if (match != null && match.groupCount >= 1) {
                                      videoId = match.group(1);
                                    }

                                    // If it's a valid 11-char YouTube ID, pull its thumbnail image artwork
                                    if (videoId != null && videoId.length == 11) {
                                      return Image.network(
                                        'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[900]),
                                      );
                                    }
                                    // Fallback background if it's a non-YouTube or broken asset link
                                    return Container(color: Colors.grey[900]);
                                  },
                                ),

                                // Dark subtle overlay tint to make the white icon pop sharply
                                Container(color: Colors.black26),

                                // Centered Play Button Icon decoration
                                const Icon(Icons.play_circle_fill, size: 50, color: Colors.white70),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
