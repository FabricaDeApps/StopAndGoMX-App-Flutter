enum DashboardSocialMediaType { image, video }

DashboardSocialMediaType _mediaTypeFromString(String value) {
  switch (value.trim().toLowerCase()) {
    case 'video':
      return DashboardSocialMediaType.video;
    case 'image':
    default:
      return DashboardSocialMediaType.image;
  }
}

class DashboardSocialMention {
  final int id;
  final String name;

  const DashboardSocialMention({required this.id, required this.name});

  factory DashboardSocialMention.fromJson(Map<String, dynamic> json) {
    return DashboardSocialMention(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
    );
  }
}

class DashboardMentionableUser {
  final int id;
  final String name;
  final String avatarUrl;
  final String roleLabel;

  const DashboardMentionableUser({
    required this.id,
    required this.name,
    this.avatarUrl = '',
    this.roleLabel = '',
  });

  factory DashboardMentionableUser.fromJson(Map<String, dynamic> json) {
    return DashboardMentionableUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      avatarUrl: (json['avatar_url'] ?? '').toString(),
      roleLabel: (json['role_label'] ?? '').toString(),
    );
  }
}

class DashboardSocialMediaItem {
  final int? id;
  final DashboardSocialMediaType type;
  final String source;
  final String remoteUrl;
  final String thumbnailUrl;
  final bool isLocal;
  final String? videoDurationLabel;
  final int order;
  final int? width;
  final int? height;

  const DashboardSocialMediaItem({
    this.id,
    required this.type,
    required this.source,
    this.remoteUrl = '',
    this.thumbnailUrl = '',
    this.isLocal = false,
    this.videoDurationLabel,
    this.order = 0,
    this.width,
    this.height,
  });

  bool get isVideo => type == DashboardSocialMediaType.video;

  factory DashboardSocialMediaItem.fromJson(Map<String, dynamic> json) {
    final type = _mediaTypeFromString((json['type'] ?? '').toString());
    final url = (json['url'] ?? '').toString();
    final thumbnailUrl = (json['thumbnail_url'] ?? '').toString();

    return DashboardSocialMediaItem(
      id: (json['id'] as num?)?.toInt(),
      type: type,
      source: type == DashboardSocialMediaType.video
          ? (thumbnailUrl.isNotEmpty ? thumbnailUrl : url)
          : url,
      remoteUrl: url,
      thumbnailUrl: thumbnailUrl,
      videoDurationLabel: json['duration_label']?.toString(),
      order: (json['order'] as num?)?.toInt() ?? 0,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
    );
  }

  DashboardSocialMediaItem copyWith({
    int? id,
    DashboardSocialMediaType? type,
    String? source,
    String? remoteUrl,
    String? thumbnailUrl,
    bool? isLocal,
    String? videoDurationLabel,
    int? order,
    int? width,
    int? height,
  }) {
    return DashboardSocialMediaItem(
      id: id ?? this.id,
      type: type ?? this.type,
      source: source ?? this.source,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isLocal: isLocal ?? this.isLocal,
      videoDurationLabel: videoDurationLabel ?? this.videoDurationLabel,
      order: order ?? this.order,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}

class DashboardSocialComment {
  final int id;
  final int authorId;
  final String authorName;
  final String authorAvatarUrl;
  final String message;
  final String timeLabel;
  final int likesCount;
  final bool isLiked;

  const DashboardSocialComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl = '',
    required this.message,
    required this.timeLabel,
    this.likesCount = 0,
    this.isLiked = false,
  });

  factory DashboardSocialComment.fromJson(Map<String, dynamic> json) {
    final rawAuthor = Map<String, dynamic>.from(
      (json['author'] as Map?) ?? const {},
    );

    return DashboardSocialComment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      authorId: (rawAuthor['id'] as num?)?.toInt() ?? 0,
      authorName: (rawAuthor['name'] ?? '').toString(),
      authorAvatarUrl: (rawAuthor['avatar_url'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      timeLabel: (json['time_label'] ?? '').toString(),
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      isLiked: json['is_liked'] == true,
    );
  }

  DashboardSocialComment copyWith({
    int? id,
    int? authorId,
    String? authorName,
    String? authorAvatarUrl,
    String? message,
    String? timeLabel,
    int? likesCount,
    bool? isLiked,
  }) {
    return DashboardSocialComment(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      message: message ?? this.message,
      timeLabel: timeLabel ?? this.timeLabel,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}

class DashboardSocialPost {
  final int id;
  final int authorId;
  final String authorName;
  final String authorRole;
  final String authorAvatarUrl;
  final String timeLabel;
  final String caption;
  final List<DashboardSocialMediaItem> media;
  final List<DashboardSocialMention> mentions;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final bool commentsExpanded;
  final List<DashboardSocialComment> comments;

  const DashboardSocialPost({
    required this.id,
    this.authorId = 0,
    required this.authorName,
    required this.authorRole,
    required this.authorAvatarUrl,
    required this.timeLabel,
    required this.caption,
    required this.media,
    this.mentions = const [],
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
    required this.commentsExpanded,
    required this.comments,
  });

  factory DashboardSocialPost.fromJson(Map<String, dynamic> json) {
    final rawAuthor = Map<String, dynamic>.from(
      (json['author'] as Map?) ?? const {},
    );
    final mentionsRaw = (json['mentions'] as List?) ?? const [];
    final commentsRaw = (json['comments'] as List?) ??
        (json['comments_preview'] as List?) ??
        const [];
    final mediaRaw = (json['media'] as List?) ?? const [];

    return DashboardSocialPost(
      id: (json['id'] as num?)?.toInt() ?? 0,
      authorId: (rawAuthor['id'] as num?)?.toInt() ?? 0,
      authorName: (rawAuthor['name'] ?? '').toString(),
      authorRole: (rawAuthor['role_label'] ?? '').toString(),
      authorAvatarUrl: (rawAuthor['avatar_url'] ?? '').toString(),
      timeLabel: (json['time_label'] ?? '').toString(),
      caption: (json['caption'] ?? '').toString(),
      media: mediaRaw
          .map(
            (e) => DashboardSocialMediaItem.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order)),
      mentions: mentionsRaw
          .map(
            (e) => DashboardSocialMention.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
      isLiked: json['is_liked'] == true,
      commentsExpanded: false,
      comments: commentsRaw
          .map(
            (e) => DashboardSocialComment.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }

  DashboardSocialPost copyWith({
    int? id,
    int? authorId,
    String? authorName,
    String? authorRole,
    String? authorAvatarUrl,
    String? timeLabel,
    String? caption,
    List<DashboardSocialMediaItem>? media,
    List<DashboardSocialMention>? mentions,
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
    bool? commentsExpanded,
    List<DashboardSocialComment>? comments,
  }) {
    return DashboardSocialPost(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      timeLabel: timeLabel ?? this.timeLabel,
      caption: caption ?? this.caption,
      media: media ?? this.media,
      mentions: mentions ?? this.mentions,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      commentsExpanded: commentsExpanded ?? this.commentsExpanded,
      comments: comments ?? this.comments,
    );
  }
}
