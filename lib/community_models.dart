class VideoDashboardFeed {
  // 🟩 CHANGE: Turned from a single item into a strongly-typed list
  final List<CathedralVideoModel> activeLiveStreams;
  final List<MemberPostModel> memberShortVideos;
  final List<CathedralVideoModel> pastServices;

  VideoDashboardFeed({
    required this.activeLiveStreams,
    required this.memberShortVideos,
    required this.pastServices,
  });

  factory VideoDashboardFeed.fromJson(Map<String, dynamic> json) {
    List<CathedralVideoModel> parsedLiveStreams = [];

    // 🟩 Check for BOTH singular and plural keys to avoid losing any active broadcasts
    final singleLive = json['activeLiveStream'];
    if (singleLive != null && singleLive is Map<String, dynamic>) {
      parsedLiveStreams.add(CathedralVideoModel.fromJson(singleLive));
    }

    final pluralLive = json['activeLiveStreams'];
    if (pluralLive != null && pluralLive is List) {
      parsedLiveStreams.addAll(
        pluralLive.map((item) => CathedralVideoModel.fromJson(item)).toList(),
      );
    }

    // Deduplicate by ID to avoid showing the same stream twice if backend sends both fields
    final seenIds = <int>{};
    final uniqueLiveStreams = parsedLiveStreams.where((v) {
      if (v.id == null) return true;
      return seenIds.add(v.id!);
    }).toList();

    var shortList = json['memberShortVideos'] ?? [];
    List<MemberPostModel> parsedShorts = [];
    if (shortList is List) {
      parsedShorts = shortList.map((item) => MemberPostModel.fromJson(item)).toList();
    }

    var pastList = json['pastServices'] ?? [];
    List<CathedralVideoModel> parsedPast = [];
    if (pastList is List) {
      parsedPast = pastList.map((item) => CathedralVideoModel.fromJson(item)).toList();
    }

    return VideoDashboardFeed(
      activeLiveStreams: uniqueLiveStreams,
      memberShortVideos: parsedShorts,
      pastServices: parsedPast,
    );
  }
}

class CathedralVideoModel {

  final int? id;
  final String title;
  final String description;
  final String videoUrl;
  final String videoType;
  final bool isActive;
  final String createdAtStr;

  CathedralVideoModel({
  this.id,
  required this.title,
  required this.description,
  required this.videoUrl,
  required this.videoType,
  required this.isActive,
  required this.createdAtStr,
  });

  factory CathedralVideoModel.fromJson(Map<String, dynamic> json) {
  return CathedralVideoModel(
  id: json['id'],
  title: json['title'] ?? '',
  description: json['description'] ?? '',
  videoUrl: json['videoUrl'] ?? '',
  videoType: json['videoType'] ?? 'PAST_SERVICE',
  isActive: json['active'] ?? false,
  createdAtStr: json['createdAtStr'] ?? '',
  );
  }
}

class MemberPostModel {
  final int id;
  final int memberId;
  final String memberName;
  final String? memberProfilePicUrl;
  final String caption;
  final String mediaUrl;
  final String mediaType;
  final String createdAtStr;
  int likesCount;
  int commentsCount;
  bool isLikedByMe;
  final List<CommentModel> comments;

  MemberPostModel({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.caption,
    required this.mediaUrl,
    required this.mediaType,
    required this.createdAtStr,
    required this.memberProfilePicUrl,
    required this.likesCount,
    required this.commentsCount,
    required this.isLikedByMe,
    required this.comments,
  });

  factory MemberPostModel.fromJson(Map<String, dynamic> json) {
    return MemberPostModel(
      id: json['id'] ?? 0,
      memberId: json['memberId'] ?? 0,
      memberName: json['memberName'] ?? 'Anonymous Member',
      caption: json['caption'] ?? '',
      mediaUrl: json['mediaUrl'] ?? '',
      memberProfilePicUrl: json['memberProfilePicUrl'],
      mediaType: json['mediaType'] ?? 'TEXT',
      createdAtStr: json['createdAtStr'] ?? '',
      likesCount: json['likesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      isLikedByMe: json['likedByMe'] ?? false,
      comments: (json['comments'] as List? ?? [])
          .map((c) => CommentModel.fromJson(c))
          .toList(),
    );
  }
}



class CommentModel {
  final int id;
  final int memberId;
  final String memberName;
  final String content;
  final String createdAtStr;

  CommentModel({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.content,
    required this.createdAtStr,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] ?? 0,
      memberId: json['memberId'] ?? 0,
      memberName: json['memberName'] ?? '',
      content: json['content'] ?? '',
      createdAtStr: json['createdAtStr'] ?? '',
    );
  }
}