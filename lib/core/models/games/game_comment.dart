class GameComment {
  final int id;
  final String authorName;
  final String message;
  final DateTime createdAt;

  GameComment({
    required this.id,
    required this.authorName,
    required this.message,
    required this.createdAt,
  });

  factory GameComment.fromJson(Map<String, dynamic> json) {
    return GameComment(
      id: json['id'] as int,
      authorName: json['author_name'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
