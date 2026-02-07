class Notice {
  final int id;
  final int organizationId;
  final int? userId;
  final int? categoryId;
  final String? categoryName;
  final int? seasonId;

  final String title;
  final String? message;
  final String? image;
  final String? attachment;

  final bool isPublished;
  final DateTime? publishedAt;
  final DateTime? expiresAt;
  final DateTime? pushSentAt;

  Notice({
    required this.id,
    required this.organizationId,
    required this.title,
    required this.isPublished,
    this.userId,
    this.categoryId,
    this.categoryName,
    this.seasonId,
    this.message,
    this.image,
    this.attachment,
    this.publishedAt,
    this.expiresAt,
    this.pushSentAt,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id'] as int,
      organizationId: json['organization_id'] as int,
      userId: json['user_id'] as int?,
      categoryId: json['category_id'] as int?,
      categoryName: json['category_name'] as String?,
      seasonId: json['season_id'] as int?,

      title: json['title'] as String,
      message: json['message'] as String?,
      image: json['image'] as String?,
      attachment: json['attachment'] as String?,

      isPublished: _bool(json['is_published']),
      publishedAt: _date(json['published_at']),
      expiresAt: _date(json['expires_at']),
      pushSentAt: _date(json['push_sent_at']),
    );
  }

  static DateTime? _date(dynamic v) {
    if (v == null || v.toString().isEmpty) return null;
    return DateTime.tryParse(v.toString());
  }

  static bool _bool(dynamic v) {
    if (v is bool) return v;
    if (v is int) return v == 1;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return false;
  }
}
