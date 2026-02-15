class GameComment {
  final int id;
  final String authorName;
  final GameCommentAuthor? author;
  final String message;
  final DateTime createdAt;
  final int likesCount;
  final bool isLikedByMe;

  GameComment({
    required this.id,
    required this.authorName,
    this.author,
    required this.message,
    required this.createdAt,
    required this.likesCount,
    required this.isLikedByMe,
  });

  factory GameComment.fromJson(Map<String, dynamic> json) {
    final authorMap = json['author'];
    final parsedAuthor = authorMap is Map
        ? GameCommentAuthor.fromJson(Map<String, dynamic>.from(authorMap))
        : null;

    return GameComment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      authorName:
          (json['author_name'] as String?)?.trim().isNotEmpty == true
          ? (json['author_name'] as String).trim()
          : (parsedAuthor?.name ?? ''),
      author: parsedAuthor,
      message: json['message'] as String? ?? '',
      createdAt:
          DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      isLikedByMe: json['is_liked_by_me'] == true,
    );
  }

  GameComment copyWith({
    int? id,
    String? authorName,
    GameCommentAuthor? author,
    String? message,
    DateTime? createdAt,
    int? likesCount,
    bool? isLikedByMe,
  }) {
    return GameComment(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      author: author ?? this.author,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      likesCount: likesCount ?? this.likesCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
    );
  }
}

class GameCommentAuthor {
  final int id;
  final String name;
  final String role;
  final String? profilePhotoUrl;

  GameCommentAuthor({
    required this.id,
    required this.name,
    required this.role,
    this.profilePhotoUrl,
  });

  factory GameCommentAuthor.fromJson(Map<String, dynamic> json) {
    final rawPhoto = (json['profile_photo_url'] ?? '').toString().trim();

    return GameCommentAuthor(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      profilePhotoUrl: rawPhoto.isEmpty ? null : rawPhoto,
    );
  }
}
