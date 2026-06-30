import 'package:flutter/material.dart';
import 'community_models.dart';
import 'feed_video_preview.dart';

class PostsTab extends StatefulWidget {
  final List<MemberPostModel> initialFeed;
  final Function(int postId) onLikeToggle;
  final Function(int postId, String commentContent) onAddComment;
  final Future<void> Function() onRefresh;

  const PostsTab({
    Key? key,
    required this.initialFeed,
    required this.onLikeToggle,
    required this.onAddComment,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<PostsTab> createState() => _PostsTabState();
}

class _PostsTabState extends State<PostsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCommentBottomSheet(BuildContext context, MemberPostModel post) {
    final TextEditingController commentInputController = TextEditingController();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 16, left: 16, right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Comments (${post.comments.length})',
                  style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)
              ),
              const SizedBox(height: 10),
              if (post.comments.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                        'Be the first to leave a word of fellowship.',
                        style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 13)
                    ),
                  ),
                )
              else
                Container(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: post.comments.length,
                    itemBuilder: (context, idx) {
                      final c = post.comments[idx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                c.memberName,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.blue[300] : Colors.black87)
                            ),
                            const SizedBox(height: 2),
                            Text(
                                c.content,
                                style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14)
                            ),
                            Text(
                                c.createdAtStr,
                                style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 10, fontStyle: FontStyle.italic)
                            ),
                            const Divider(),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentInputController,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Write a comment...',
                          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: () {
                        if (commentInputController.text.trim().isNotEmpty) {
                          widget.onAddComment(post.id, commentInputController.text.trim());
                          Navigator.pop(context);
                        }
                      },
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mainTextColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white60 : Colors.grey;

    final filteredFeed = widget.initialFeed.where((post) {
      return post.memberName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();


    return Column(
      children: [
        // 🔍 SEARCH INPUT FIELD
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            style: TextStyle(color: mainTextColor),
            decoration: InputDecoration(
              hintText: 'Search by username...',
              hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
              prefixIcon: Icon(Icons.search, color: subTextColor),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
            ),
          ),
        ),

        // TIMELINE FEED CONTAINER
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: filteredFeed.isEmpty
                ? Center(child: Text('No community updates match your search.', style: TextStyle(color: subTextColor)))
                : ListView.builder(
              itemCount: filteredFeed.length,
              itemBuilder: (context, index) {
                final post = filteredFeed[index];
                final String? serverUrl = post.mediaUrl;
                final String? avatarUrl = post.memberProfilePicUrl;

                // Build full safe resource endpoint tracking URI
                final String fullMediaUrl = serverUrl == null ? '' : (serverUrl.startsWith('http')
                    ? serverUrl
                    : 'http://192.168.100.33:8080${serverUrl.startsWith('/') ? '' : '/'}$serverUrl');

                final String fullAvatarUrl = avatarUrl == null || avatarUrl.isEmpty ? '' : (avatarUrl.startsWith('http')
                    ? avatarUrl
                    : 'http://192.168.100.33:8080${avatarUrl.startsWith('/') ? '' : '/'}$avatarUrl');

                return Card(
                  color: Theme.of(context).cardColor,
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 1.5,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top profile row header
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: isDark ? Colors.blueGrey[700] : Colors.blueGrey[100],
                              backgroundImage: fullAvatarUrl.isNotEmpty
                                  ? NetworkImage(fullAvatarUrl)
                                  : null,
                              child: (avatarUrl == null || avatarUrl.isEmpty)
                                  ? Text(
                                post.memberName.isNotEmpty ? post.memberName[0].toUpperCase() : 'C',
                                style: TextStyle(color: isDark ? Colors.white : Colors.blueGrey[800], fontWeight: FontWeight.bold),
                              )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(post.memberName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: mainTextColor)),
                                  Text(post.createdAtStr, style: TextStyle(color: subTextColor, fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Post Caption
                        if (post.caption.isNotEmpty) ...[
                          Text(post.caption, style: TextStyle(fontSize: 14, color: mainTextColor)),
                          const SizedBox(height: 10),
                        ],

                        // 🟩 SMART MEDIA BLOCK SYSTEM: Diverges paths based on file string signatures
                        if (serverUrl != null && serverUrl.isNotEmpty) ...[
                          if (post.mediaType == 'VIDEO') ...[
                            // 🎥 VIDEO MEDIA CONTAINER ROUTE
                            Container(
                              height: 200,
                              width: double.infinity,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.withOpacity(0.2)),
                              ),
                              child: Stack(
                                children: [
                                  FeedVideoPreview(videoUrl: fullMediaUrl),
                                  Positioned(
                                    bottom: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.videocam, color: Colors.redAccent, size: 12),
                                          SizedBox(width: 4),
                                          Text("Shorts", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // 📷 STANDARD IMAGE MEDIA CONTAINER ROUTE
                            Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.network(
                                fullMediaUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Center(
                                  child: Icon(Icons.broken_image_outlined, color: subTextColor, size: 24),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                        ],

                        // Interactive Action Row Footer (Like, Share, Comment)
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () => widget.onLikeToggle(post.id),
                                child: Row(
                                  children: [
                                    Icon(
                                      post.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                                      color: post.isLikedByMe ? Colors.red : subTextColor,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 5),
                                    Text('${post.likesCount}', style: TextStyle(fontSize: 13, color: subTextColor, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 25),
                              InkWell(
                                onTap: () => _openCommentBottomSheet(context, post),
                                child: Row(
                                  children: [
                                    Icon(Icons.chat_bubble_outline, color: subTextColor, size: 21),
                                    const SizedBox(width: 5),
                                    Text('${post.commentsCount}', style: TextStyle(fontSize: 13, color: subTextColor, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 25),
                              InkWell(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Sharing fellowship post...'), duration: Duration(seconds: 1)),
                                  );
                                },
                                child: Row(
                                  children: [
                                    Icon(Icons.share_outlined, color: subTextColor, size: 21),
                                    const SizedBox(width: 5),
                                    Text('Share', style: TextStyle(fontSize: 13, color: subTextColor, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}