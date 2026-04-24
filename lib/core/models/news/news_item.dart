class NewsItem {
  final int id;
  final String sport;
  final String sourceName;
  final String sourceCountry;
  final String sourceLanguage;
  final String title;
  final String summary;
  final String articleUrl;
  final String imageUrl;
  final String status;
  final int? relevanceScore;
  final DateTime? publishedAt;
  final DateTime? fetchedAt;
  final DateTime? seenAt;
  final bool isSeen;

  const NewsItem({
    required this.id,
    required this.sport,
    required this.sourceName,
    required this.sourceCountry,
    required this.sourceLanguage,
    required this.title,
    required this.summary,
    required this.articleUrl,
    required this.imageUrl,
    required this.status,
    required this.relevanceScore,
    required this.publishedAt,
    required this.fetchedAt,
    required this.seenAt,
    required this.isSeen,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      sport: (json['sport'] ?? '').toString(),
      sourceName: (json['source_name'] ?? '').toString(),
      sourceCountry: (json['source_country'] ?? '').toString(),
      sourceLanguage: (json['source_language'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      articleUrl: (json['article_url'] ?? '').toString(),
      imageUrl: (json['image_url'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      relevanceScore: (json['relevance_score'] as num?)?.toInt(),
      publishedAt: _parseDate(json['published_at']),
      fetchedAt: _parseDate(json['fetched_at']),
      seenAt: _parseDate(json['seen_at']),
      isSeen: json['is_seen'] == true,
    );
  }

  NewsItem copyWith({DateTime? seenAt, bool? isSeen}) {
    return NewsItem(
      id: id,
      sport: sport,
      sourceName: sourceName,
      sourceCountry: sourceCountry,
      sourceLanguage: sourceLanguage,
      title: title,
      summary: summary,
      articleUrl: articleUrl,
      imageUrl: imageUrl,
      status: status,
      relevanceScore: relevanceScore,
      publishedAt: publishedAt,
      fetchedAt: fetchedAt,
      seenAt: seenAt ?? this.seenAt,
      isSeen: isSeen ?? this.isSeen,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }
}
