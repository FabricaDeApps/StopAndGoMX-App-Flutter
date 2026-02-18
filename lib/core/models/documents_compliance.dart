class DocumentsComplianceMeta {
  final int orgId;
  final int categoryId;
  final String q;
  final String status;
  final int perPage;
  final int currentPage;
  final int lastPage;
  final int total;

  const DocumentsComplianceMeta({
    required this.orgId,
    required this.categoryId,
    required this.q,
    required this.status,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory DocumentsComplianceMeta.fromJson(Map<String, dynamic> json) {
    return DocumentsComplianceMeta(
      orgId: (json['org_id'] ?? 0) as int,
      categoryId: (json['category_id'] ?? 0) as int,
      q: json['q']?.toString() ?? '',
      status: json['status']?.toString() ?? 'all',
      perPage: (json['per_page'] ?? 15) as int,
      currentPage: (json['current_page'] ?? 1) as int,
      lastPage: (json['last_page'] ?? 1) as int,
      total: (json['total'] ?? 0) as int,
    );
  }
}

class DocumentsComplianceTotals {
  final int requiredDocuments;
  final int listedPlayers;
  final int completePlayers;
  final int incompletePlayers;

  const DocumentsComplianceTotals({
    required this.requiredDocuments,
    required this.listedPlayers,
    required this.completePlayers,
    required this.incompletePlayers,
  });

  factory DocumentsComplianceTotals.fromJson(Map<String, dynamic> json) {
    return DocumentsComplianceTotals(
      requiredDocuments: (json['required_documents'] ?? 0) as int,
      listedPlayers: (json['listed_players'] ?? 0) as int,
      completePlayers: (json['complete_players'] ?? 0) as int,
      incompletePlayers: (json['incomplete_players'] ?? 0) as int,
    );
  }
}

class DocumentsCompliancePlayerItem {
  final int playerId;
  final String firstName;
  final String lastName;
  final String email;
  final int requiredTotal;
  final int completed;
  final int missing;
  final double percentage;

  const DocumentsCompliancePlayerItem({
    required this.playerId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.requiredTotal,
    required this.completed,
    required this.missing,
    required this.percentage,
  });

  String get fullName {
    final value = '$firstName $lastName'.trim();
    return value.isEmpty ? 'Jugador' : value;
  }

  factory DocumentsCompliancePlayerItem.fromJson(Map<String, dynamic> json) {
    return DocumentsCompliancePlayerItem(
      playerId: (json['player_id'] ?? 0) as int,
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      requiredTotal: (json['required_total'] ?? 0) as int,
      completed: (json['completed'] ?? 0) as int,
      missing: (json['missing'] ?? 0) as int,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class DocumentsComplianceResponse {
  final DocumentsComplianceMeta meta;
  final DocumentsComplianceTotals totals;
  final List<DocumentsCompliancePlayerItem> data;

  const DocumentsComplianceResponse({
    required this.meta,
    required this.totals,
    required this.data,
  });

  factory DocumentsComplianceResponse.fromJson(Map<String, dynamic> json) {
    final rawData = (json['data'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(
          (e) => DocumentsCompliancePlayerItem.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();

    return DocumentsComplianceResponse(
      meta: DocumentsComplianceMeta.fromJson(
        json['meta'] is Map
            ? Map<String, dynamic>.from(json['meta'] as Map)
            : <String, dynamic>{},
      ),
      totals: DocumentsComplianceTotals.fromJson(
        json['totals'] is Map
            ? Map<String, dynamic>.from(json['totals'] as Map)
            : <String, dynamic>{},
      ),
      data: rawData,
    );
  }
}
