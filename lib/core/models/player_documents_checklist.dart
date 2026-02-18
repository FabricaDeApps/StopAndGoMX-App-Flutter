import 'package:stopandgo/core/models/player_document.dart';

class PlayerDocumentsChecklistSummary {
  final int totalRequired;
  final int completed;
  final int missing;
  final double percentage;

  const PlayerDocumentsChecklistSummary({
    required this.totalRequired,
    required this.completed,
    required this.missing,
    required this.percentage,
  });

  factory PlayerDocumentsChecklistSummary.fromJson(Map<String, dynamic> json) {
    return PlayerDocumentsChecklistSummary(
      totalRequired: (json['total_required'] ?? 0) as int,
      completed: (json['completed'] ?? 0) as int,
      missing: (json['missing'] ?? 0) as int,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class PlayerRequiredDocumentItem {
  final int id;
  final String name;
  final String slug;
  final String description;
  final bool isRequired;
  final bool isActive;
  final int sortOrder;
  final String status;
  final PlayerDocument? document;

  const PlayerRequiredDocumentItem({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.isRequired,
    required this.isActive,
    required this.sortOrder,
    required this.status,
    this.document,
  });

  bool get isUploaded => status.toLowerCase() == 'uploaded';

  factory PlayerRequiredDocumentItem.fromJson(Map<String, dynamic> json) {
    final docJson = json['document'];
    return PlayerRequiredDocumentItem(
      id: (json['id'] ?? 0) as int,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      isRequired: json['is_required'] == true,
      isActive: json['is_active'] == true,
      sortOrder: (json['sort_order'] ?? 0) as int,
      status: json['status']?.toString() ?? 'missing',
      document: docJson is Map<String, dynamic>
          ? PlayerDocument.fromJson(docJson)
          : null,
    );
  }
}

class PlayerDocumentsChecklist {
  final int playerId;
  final int organizationId;
  final PlayerDocumentsChecklistSummary summary;
  final List<PlayerRequiredDocumentItem> items;

  const PlayerDocumentsChecklist({
    required this.playerId,
    required this.organizationId,
    required this.summary,
    required this.items,
  });

  factory PlayerDocumentsChecklist.fromJson(Map<String, dynamic> json) {
    final rawItems =
        (json['items'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map(
              (item) => PlayerRequiredDocumentItem.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return PlayerDocumentsChecklist(
      playerId: (json['player_id'] ?? 0) as int,
      organizationId: (json['organization_id'] ?? 0) as int,
      summary: PlayerDocumentsChecklistSummary.fromJson(
        (json['summary'] as Map<String, dynamic>? ?? <String, dynamic>{}),
      ),
      items: rawItems,
    );
  }
}
