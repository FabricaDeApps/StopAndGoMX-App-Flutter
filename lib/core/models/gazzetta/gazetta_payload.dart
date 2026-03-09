class GazettaPayload {
  final String? summary;
  final List<String> highlights;
  final List<GazettaMatch> matches;
  final List<GazettaSection> sections;

  const GazettaPayload({
    this.summary,
    this.highlights = const [],
    this.matches = const [],
    this.sections = const [],
  });

  factory GazettaPayload.fromJson(dynamic json) {
    if (json is! Map) return const GazettaPayload();
    final map = Map<String, dynamic>.from(json);

    final highlightsRaw = map['highlights'];
    final matchesRaw = map['matches'];
    final sectionsRaw = map['sections'];

    return GazettaPayload(
      summary: _asString(map['summary']),
      highlights: highlightsRaw is List
          ? highlightsRaw
                .map((e) => e.toString())
                .where((e) => e.isNotEmpty)
                .toList()
          : const [],
      matches: matchesRaw is List
          ? matchesRaw
                .whereType<Map>()
                .map((e) => GazettaMatch.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
      sections: sectionsRaw is List
          ? sectionsRaw
                .whereType<Map>()
                .map(
                  (e) => GazettaSection.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'summary': summary,
    'highlights': highlights,
    'matches': matches.map((e) => e.toJson()).toList(),
    'sections': sections.map((e) => e.toJson()).toList(),
  };

  static String? _asString(dynamic value) {
    final s = value?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }
}

class GazettaMatch {
  final String? title;
  final String? opponent;
  final int? homeScore;
  final int? opponentScore;
  final String? imageUrl;

  const GazettaMatch({
    this.title,
    this.opponent,
    this.homeScore,
    this.opponentScore,
    this.imageUrl,
  });

  factory GazettaMatch.fromJson(Map<String, dynamic> json) {
    return GazettaMatch(
      title: _asString(json['title']),
      opponent: _asString(json['opponent'] ?? json['opponent_name']),
      homeScore: _asInt(json['home_score']),
      opponentScore: _asInt(json['opponent_score']),
      imageUrl: _asString(json['image'] ?? json['image_url'] ?? json['photo']),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'opponent': opponent,
    'home_score': homeScore,
    'opponent_score': opponentScore,
    'image_url': imageUrl,
  };
}

class GazettaSection {
  final String? title;
  final String? content;

  const GazettaSection({this.title, this.content});

  factory GazettaSection.fromJson(Map<String, dynamic> json) {
    return GazettaSection(
      title: _asString(json['title']),
      content: _asString(json['content'] ?? json['body']),
    );
  }

  Map<String, dynamic> toJson() => {'title': title, 'content': content};
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

String? _asString(dynamic value) {
  final s = value?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}
