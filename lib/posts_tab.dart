import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:untitled/report_post.dart';
import 'package:untitled/session_manager.dart';
import 'community_models.dart';
import 'deep_link_service.dart';
import 'feed_video_preview.dart';
import 'bb_text_formatter.dart';
import 'file_download_service.dart';

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


                return CommunityPostCard(
                  post: post,
                  isAdminPreview: false,
                  onLikeToggle: (id) => widget.onLikeToggle(id),
                  onCommentTap: () => _openCommentBottomSheet(context, post),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}


class CommunityPostCard extends StatelessWidget {
  final dynamic post; // Pass your MemberPost DTO map or class model here
  final bool isAdminPreview;
  final Function(int)? onLikeToggle;
  final VoidCallback? onCommentTap;

  const CommunityPostCard({
    Key? key,
    required this.post,
    this.isAdminPreview = false,
    this.onLikeToggle,
    this.onCommentTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mainTextColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white60 : Colors.grey;

    final String? serverUrl = post is Map ? post['mediaUrl'] : post.mediaUrl;
    final String? avatarUrl = post is Map ? post['memberProfilePicUrl'] : post.memberProfilePicUrl;
    final String memberName = post is Map ? (post['memberName'] ?? 'Unknown') : post.memberName;
    final String createdAtStr = post is Map ? (post['createdAtStr'] ?? '') : post.createdAtStr;
    final String caption = post is Map ? (post['caption'] ?? '') : post.caption;
    final String mediaType = post is Map ? (post['mediaType'] ?? 'IMAGE') : post.mediaType;
    final bool isLikedByMe = post is Map ? (post['isLikedByMe'] ?? false) : post.isLikedByMe;
    final int likesCount = post is Map ? (post['likesCount'] ?? 0) : post.likesCount;
    final int commentsCount = post is Map ? (post['commentsCount'] ?? 0) : post.commentsCount;
    final int postId = post is Map ? (post['id'] ?? 0) : post.id;

    // Build resource endpoints
    final String fullMediaUrl = serverUrl == null ? '' : (serverUrl.startsWith('http')
        ? serverUrl
        : 'http://192.168.100.33:8080${serverUrl.startsWith('/') ? '' : '/'}$serverUrl');

    final String fullAvatarUrl = avatarUrl == null || avatarUrl.isEmpty ? '' : (avatarUrl.startsWith('http')
        ? avatarUrl
        : 'http://192.168.100.33:8080${avatarUrl.startsWith('/') ? '' : '/'}$avatarUrl');

    return Card(
      color: Theme.of(context).cardColor,
      margin: isAdminPreview ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: isAdminPreview ? 0 : 1.5,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isDark ? Colors.blueGrey[700] : Colors.blueGrey[100],
                  backgroundImage: fullAvatarUrl.isNotEmpty ? NetworkImage(fullAvatarUrl) : null,
                  child: (avatarUrl == null || avatarUrl.isEmpty)
                      ? Text(
                    memberName.isNotEmpty ? memberName[0].toUpperCase() : 'C',
                    style: TextStyle(color: isDark ? Colors.white : Colors.blueGrey[800], fontWeight: FontWeight.bold),
                  )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(memberName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: mainTextColor)),
                      Text(createdAtStr, style: TextStyle(color: subTextColor, fontSize: 11)),
                    ],
                  ),
                ),

                // Hide popup options if we are just previewing inside the admin panel
                if (!isAdminPreview)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: subTextColor),
                    onSelected: (value) {
                      if (value == 'report') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReportPostScreen(
                              postId: postId.toString(),
                              postAuthor: memberName,
                              reportingMemberId: SessionManager.currentUserId,
                            ),
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: 'report',
                        child: Row(
                          children: [
                            Icon(Icons.report_problem_outlined, color: Colors.redAccent, size: 20),
                            SizedBox(width: 10),
                            Text('Report Content', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Post Caption
            if (caption.isNotEmpty) ...[
              Text(caption, style: TextStyle(color: mainTextColor, fontSize: 14)), // Fallback or use BBText
              const SizedBox(height: 10),
            ],

            // Media Assets Route
            if (serverUrl != null && serverUrl.isNotEmpty) ...[
              if (mediaType == 'VIDEO') ...[
                Container(
                  height: 200,
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
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
                              const SizedBox(width: 4),
                              Text("Shorts", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
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

            // Action Footer (Like, Comment, Share) - Hidden or Disabled in admin mode
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: isAdminPreview ? null : () => onLikeToggle?.call(postId),
                    child: Row(
                      children: [
                        Icon(
                          isLikedByMe ? Icons.favorite : Icons.favorite_border,
                          color: isLikedByMe ? Colors.red : subTextColor,
                          size: 22,
                        ),
                        const SizedBox(width: 5),
                        Text('$likesCount', style: TextStyle(fontSize: 13, color: subTextColor, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 25),
                  InkWell(
                    onTap: isAdminPreview ? null : onCommentTap,
                    child: Row(
                      children: [
                        Icon(Icons.chat_bubble_outline, color: subTextColor, size: 21),
                        const SizedBox(width: 5),
                        Text('$commentsCount', style: TextStyle(fontSize: 13, color: subTextColor, fontWeight: FontWeight.w500)),
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
  }
}
