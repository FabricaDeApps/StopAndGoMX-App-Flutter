import 'package:stopandgo/core/models/news/news_item.dart';

class NewsFeedResponse {
  final List<NewsItem> data;
  final NewsFeedMeta meta;

  const NewsFeedResponse({required this.data, required this.meta});

  factory NewsFeedResponse.fromJson(Map<String, dynamic> json) {
    final items = (json['data'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => NewsItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final metaMap = json['meta'] is Map<String, dynamic>
        ? json['meta'] as Map<String, dynamic>
        : json['meta'] is Map
        ? Map<String, dynamic>.from(json['meta'] as Map)
        : const <String, dynamic>{};

    return NewsFeedResponse(data: items, meta: NewsFeedMeta.fromJson(metaMap));
  }
}

class NewsFeedMeta {
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;
  final List<String> sports;

  const NewsFeedMeta({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
    required this.sports,
  });

  factory NewsFeedMeta.fromJson(Map<String, dynamic> json) {
    return NewsFeedMeta(
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      perPage: (json['per_page'] as num?)?.toInt() ?? 15,
      total: (json['total'] as num?)?.toInt() ?? 0,
      lastPage: (json['last_page'] as num?)?.toInt() ?? 1,
      sports: (json['sports'] as List? ?? const [])
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList(),
    );
  }
}
