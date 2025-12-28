class PaginatedResponse<T> {
  final int currentPage;
  final List<T> data;
  final String? nextPageUrl;
  final String? prevPageUrl;
  final int? total;
  final int? lastPage;

  PaginatedResponse({
    required this.currentPage,
    required this.data,
    required this.nextPageUrl,
    required this.prevPageUrl,
    this.total,
    this.lastPage,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final rawList = (json['data'] as List? ?? const []);
    return PaginatedResponse<T>(
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      data: rawList
          .whereType<Map>()
          .map((e) => fromJsonT(Map<String, dynamic>.from(e)))
          .toList(),
      nextPageUrl: json['next_page_url'] as String?,
      prevPageUrl: json['prev_page_url'] as String?,
      total: (json['total'] as num?)?.toInt(),
      lastPage: (json['last_page'] as num?)?.toInt(),
    );
  }
}
