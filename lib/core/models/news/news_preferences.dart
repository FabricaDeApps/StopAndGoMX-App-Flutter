class NewsPreferences {
  final bool newsPushEnabled;
  final List<NewsPreferenceSport> sports;

  const NewsPreferences({required this.newsPushEnabled, required this.sports});

  factory NewsPreferences.fromJson(Map<String, dynamic> json) {
    final sports = (json['sports'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => NewsPreferenceSport.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return NewsPreferences(
      newsPushEnabled: json['news_push_enabled'] == true,
      sports: sports,
    );
  }
}

class NewsPreferenceSport {
  final String sport;
  final String label;
  final bool isEnabled;
  final bool pushEnabled;

  const NewsPreferenceSport({
    required this.sport,
    required this.label,
    required this.isEnabled,
    required this.pushEnabled,
  });

  factory NewsPreferenceSport.fromJson(Map<String, dynamic> json) {
    return NewsPreferenceSport(
      sport: (json['sport'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      isEnabled: json['is_enabled'] == true,
      pushEnabled: json['push_enabled'] == true,
    );
  }
}
