class PlayerFileMeta {
  final String tab;
  final List<String> tabs;
  final int? perPage;
  final int? currentPage;
  final int? lastPage;
  final int? total;

  const PlayerFileMeta({
    required this.tab,
    required this.tabs,
    this.perPage,
    this.currentPage,
    this.lastPage,
    this.total,
  });

  bool get isPaginated =>
      perPage != null &&
      currentPage != null &&
      lastPage != null &&
      total != null;

  factory PlayerFileMeta.fromJson(Map<String, dynamic> json) {
    final rawTabs = (json['tabs'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();
    return PlayerFileMeta(
      tab: json['tab']?.toString() ?? 'categories',
      tabs: rawTabs,
      perPage: json['per_page'] as int?,
      currentPage: json['current_page'] as int?,
      lastPage: json['last_page'] as int?,
      total: json['total'] as int?,
    );
  }
}

class PlayerFilePlayer {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String position;
  final String photoUrl;

  const PlayerFilePlayer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.position,
    required this.photoUrl,
  });

  String get fullName {
    final value = '$firstName $lastName'.trim();
    return value.isEmpty ? 'Jugador' : value;
  }

  factory PlayerFilePlayer.fromJson(Map<String, dynamic> json) {
    return PlayerFilePlayer(
      id: (json['id'] ?? 0) as int,
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      position: json['position']?.toString() ?? '',
      photoUrl: json['photo_url']?.toString() ?? '',
    );
  }
}

class PlayerFileCategoryItem {
  final int id;
  final String name;
  final int? jerseyNumber;
  final bool isCaptain;
  final String status;

  const PlayerFileCategoryItem({
    required this.id,
    required this.name,
    required this.jerseyNumber,
    required this.isCaptain,
    required this.status,
  });

  factory PlayerFileCategoryItem.fromJson(Map<String, dynamic> json) {
    final rawJersey = json['jersey_number'];
    return PlayerFileCategoryItem(
      id: (json['id'] ?? 0) as int,
      name: json['name']?.toString() ?? '',
      jerseyNumber: rawJersey is int ? rawJersey : int.tryParse('$rawJersey'),
      isCaptain: json['is_captain'] == true,
      status: json['status']?.toString() ?? '',
    );
  }
}

class PlayerFileTrainingCategory {
  final int id;
  final String name;

  const PlayerFileTrainingCategory({required this.id, required this.name});

  factory PlayerFileTrainingCategory.fromJson(Map<String, dynamic> json) {
    return PlayerFileTrainingCategory(
      id: (json['id'] ?? 0) as int,
      name: json['name']?.toString() ?? '',
    );
  }
}

class PlayerFileTraining {
  final int id;
  final DateTime? startsAt;
  final String venue;
  final PlayerFileTrainingCategory? category;

  const PlayerFileTraining({
    required this.id,
    required this.startsAt,
    required this.venue,
    required this.category,
  });

  factory PlayerFileTraining.fromJson(Map<String, dynamic> json) {
    final rawCategory = json['category'];
    return PlayerFileTraining(
      id: (json['id'] ?? 0) as int,
      startsAt: _parseDate(json['starts_at']?.toString()),
      venue: json['venue']?.toString() ?? '',
      category: rawCategory is Map<String, dynamic>
          ? PlayerFileTrainingCategory.fromJson(rawCategory)
          : (rawCategory is Map
                ? PlayerFileTrainingCategory.fromJson(
                    Map<String, dynamic>.from(rawCategory),
                  )
                : null),
    );
  }
}

class PlayerFileTrainingItem {
  final int id;
  final String status;
  final String note;
  final PlayerFileTraining? training;

  const PlayerFileTrainingItem({
    required this.id,
    required this.status,
    required this.note,
    required this.training,
  });

  factory PlayerFileTrainingItem.fromJson(Map<String, dynamic> json) {
    final rawTraining = json['training'];
    return PlayerFileTrainingItem(
      id: (json['id'] ?? 0) as int,
      status: json['status']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      training: rawTraining is Map<String, dynamic>
          ? PlayerFileTraining.fromJson(rawTraining)
          : (rawTraining is Map
                ? PlayerFileTraining.fromJson(
                    Map<String, dynamic>.from(rawTraining),
                  )
                : null),
    );
  }
}

class PlayerFilePaymentCategory {
  final int id;
  final String name;

  const PlayerFilePaymentCategory({required this.id, required this.name});

  factory PlayerFilePaymentCategory.fromJson(Map<String, dynamic> json) {
    return PlayerFilePaymentCategory(
      id: (json['id'] ?? 0) as int,
      name: json['name']?.toString() ?? '',
    );
  }
}

class PlayerFilePaymentItem {
  final int id;
  final String concept;
  final String status;
  final DateTime? dueDate;
  final PlayerFilePaymentCategory? category;
  final double amount;
  final double totalDue;
  final double amountPaid;
  final double balance;

  const PlayerFilePaymentItem({
    required this.id,
    required this.concept,
    required this.status,
    required this.dueDate,
    required this.category,
    required this.amount,
    required this.totalDue,
    required this.amountPaid,
    required this.balance,
  });

  factory PlayerFilePaymentItem.fromJson(Map<String, dynamic> json) {
    final rawCategory = json['category'];
    return PlayerFilePaymentItem(
      id: (json['id'] ?? 0) as int,
      concept: json['concept']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      dueDate: _parseDate(json['due_date']?.toString()),
      category: rawCategory is Map<String, dynamic>
          ? PlayerFilePaymentCategory.fromJson(rawCategory)
          : (rawCategory is Map
                ? PlayerFilePaymentCategory.fromJson(
                    Map<String, dynamic>.from(rawCategory),
                  )
                : null),
      amount: (json['amount'] ?? 0).toDouble(),
      totalDue: (json['total_due'] ?? 0).toDouble(),
      amountPaid: (json['amount_paid'] ?? 0).toDouble(),
      balance: (json['balance'] ?? 0).toDouble(),
    );
  }
}

class PlayerFileRequiredDocument {
  final int id;
  final String name;
  final String slug;

  const PlayerFileRequiredDocument({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory PlayerFileRequiredDocument.fromJson(Map<String, dynamic> json) {
    return PlayerFileRequiredDocument(
      id: (json['id'] ?? 0) as int,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
    );
  }
}

class PlayerFileDocumentItem {
  final int id;
  final String originalName;
  final String mimeType;
  final int size;
  final DateTime? uploadedAt;
  final String downloadUrl;
  final int? requiredDocumentId;
  final PlayerFileRequiredDocument? requiredDocument;

  const PlayerFileDocumentItem({
    required this.id,
    required this.originalName,
    required this.mimeType,
    required this.size,
    required this.uploadedAt,
    required this.downloadUrl,
    required this.requiredDocumentId,
    required this.requiredDocument,
  });

  factory PlayerFileDocumentItem.fromJson(Map<String, dynamic> json) {
    final rawRequired = json['required_document'];
    return PlayerFileDocumentItem(
      id: (json['id'] ?? 0) as int,
      originalName: json['original_name']?.toString() ?? '',
      mimeType: json['mime_type']?.toString() ?? '',
      size: (json['size'] ?? 0) as int,
      uploadedAt: _parseDate(json['uploaded_at']?.toString()),
      downloadUrl: json['download_url']?.toString() ?? '',
      requiredDocumentId: json['required_document_id'] as int?,
      requiredDocument: rawRequired is Map<String, dynamic>
          ? PlayerFileRequiredDocument.fromJson(rawRequired)
          : (rawRequired is Map
                ? PlayerFileRequiredDocument.fromJson(
                    Map<String, dynamic>.from(rawRequired),
                  )
                : null),
    );
  }
}

class PlayerFileResponse {
  final PlayerFileMeta meta;
  final PlayerFilePlayer player;
  final List<PlayerFileCategoryItem> categories;
  final List<PlayerFileTrainingItem> trainings;
  final List<PlayerFilePaymentItem> payments;
  final List<PlayerFileDocumentItem> documents;

  const PlayerFileResponse({
    required this.meta,
    required this.player,
    required this.categories,
    required this.trainings,
    required this.payments,
    required this.documents,
  });

  factory PlayerFileResponse.fromJson(
    Map<String, dynamic> json, {
    required String tab,
  }) {
    final rawData = (json['data'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    List<PlayerFileCategoryItem> categories = const [];
    List<PlayerFileTrainingItem> trainings = const [];
    List<PlayerFilePaymentItem> payments = const [];
    List<PlayerFileDocumentItem> documents = const [];

    switch (tab) {
      case 'categories':
        categories = rawData.map(PlayerFileCategoryItem.fromJson).toList();
        break;
      case 'trainings':
        trainings = rawData.map(PlayerFileTrainingItem.fromJson).toList();
        break;
      case 'payments':
        payments = rawData.map(PlayerFilePaymentItem.fromJson).toList();
        break;
      case 'documents':
        documents = rawData.map(PlayerFileDocumentItem.fromJson).toList();
        break;
      default:
        break;
    }

    final rawPlayer = json['player'] is Map
        ? Map<String, dynamic>.from(json['player'] as Map)
        : <String, dynamic>{};

    return PlayerFileResponse(
      meta: PlayerFileMeta.fromJson(
        json['meta'] is Map
            ? Map<String, dynamic>.from(json['meta'] as Map)
            : <String, dynamic>{},
      ),
      player: PlayerFilePlayer.fromJson(rawPlayer),
      categories: categories,
      trainings: trainings,
      payments: payments,
      documents: documents,
    );
  }
}

DateTime? _parseDate(String? s) {
  if (s == null || s.isEmpty) return null;
  return DateTime.tryParse(s);
}
