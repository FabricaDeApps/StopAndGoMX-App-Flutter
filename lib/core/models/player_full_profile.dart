class OrganizationPlayerFullProfileResponse {
  final OrganizationPlayerFullProfileData data;
  final OrganizationPlayerFullProfileMeta meta;

  const OrganizationPlayerFullProfileResponse({
    required this.data,
    required this.meta,
  });

  factory OrganizationPlayerFullProfileResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawData = json['data'];
    final rawMeta = json['meta'];

    return OrganizationPlayerFullProfileResponse(
      data: OrganizationPlayerFullProfileData.fromJson(
        rawData is Map ? Map<String, dynamic>.from(rawData) : const {},
      ),
      meta: OrganizationPlayerFullProfileMeta.fromJson(
        rawMeta is Map ? Map<String, dynamic>.from(rawMeta) : const {},
      ),
    );
  }
}

class OrganizationPlayerFullProfileData {
  final OrganizationPlayerIdentity player;
  final OrganizationPlayerPersonal personal;
  final OrganizationPlayerSport sport;
  final OrganizationPlayerHealth health;
  final OrganizationPlayerFamily family;
  final List<OrganizationPlayerCategoryAssignment> categories;
  final OrganizationPlayerDocuments documents;
  final OrganizationPlayerPayments payments;

  const OrganizationPlayerFullProfileData({
    required this.player,
    required this.personal,
    required this.sport,
    required this.health,
    required this.family,
    required this.categories,
    required this.documents,
    required this.payments,
  });

  factory OrganizationPlayerFullProfileData.fromJson(
      Map<String, dynamic> json) {
    return OrganizationPlayerFullProfileData(
      player: OrganizationPlayerIdentity.fromJson(
        _asMap(json['player']),
      ),
      personal: OrganizationPlayerPersonal.fromJson(
        _asMap(json['personal']),
      ),
      sport: OrganizationPlayerSport.fromJson(_asMap(json['sport'])),
      health: OrganizationPlayerHealth.fromJson(_asMap(json['health'])),
      family: OrganizationPlayerFamily.fromJson(_asMap(json['family'])),
      categories: _asList(json['categories'])
          .map(OrganizationPlayerCategoryAssignment.fromJson)
          .toList(),
      documents:
          OrganizationPlayerDocuments.fromJson(_asMap(json['documents'])),
      payments: OrganizationPlayerPayments.fromJson(_asMap(json['payments'])),
    );
  }
}

class OrganizationPlayerFullProfileMeta {
  final String viewerRole;
  final int organizationId;
  final int playerId;

  const OrganizationPlayerFullProfileMeta({
    required this.viewerRole,
    required this.organizationId,
    required this.playerId,
  });

  factory OrganizationPlayerFullProfileMeta.fromJson(
      Map<String, dynamic> json) {
    return OrganizationPlayerFullProfileMeta(
      viewerRole: json['viewer_role']?.toString() ?? '',
      organizationId: _toInt(json['organization_id']),
      playerId: _toInt(json['player_id']),
    );
  }
}

class OrganizationPlayerIdentity {
  final int id;
  final int organizationId;
  final OrganizationPlayerOrganization organization;
  final String firstName;
  final String lastName;
  final String fullName;
  final String alias;
  final String photoUrl;
  final bool isActive;
  final bool confirmed;
  final DateTime? createdAt;

  const OrganizationPlayerIdentity({
    required this.id,
    required this.organizationId,
    required this.organization,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.alias,
    required this.photoUrl,
    required this.isActive,
    required this.confirmed,
    required this.createdAt,
  });

  factory OrganizationPlayerIdentity.fromJson(Map<String, dynamic> json) {
    final firstName = json['first_name']?.toString() ?? '';
    final lastName = json['last_name']?.toString() ?? '';
    final computedFullName = '$firstName $lastName'.trim();

    return OrganizationPlayerIdentity(
      id: _toInt(json['id']),
      organizationId: _toInt(json['organization_id']),
      organization: OrganizationPlayerOrganization.fromJson(
        _asMap(json['organization']),
      ),
      firstName: firstName,
      lastName: lastName,
      fullName: (json['full_name']?.toString() ?? computedFullName).trim(),
      alias: json['alias']?.toString() ?? '',
      photoUrl: json['photo_url']?.toString() ?? '',
      isActive: json['is_active'] == true,
      confirmed: json['confirmed'] == true,
      createdAt: _parseDate(json['created_at']),
    );
  }
}

class OrganizationPlayerOrganization {
  final int id;
  final String name;
  final String slug;
  final String logoUrl;

  const OrganizationPlayerOrganization({
    required this.id,
    required this.name,
    required this.slug,
    required this.logoUrl,
  });

  factory OrganizationPlayerOrganization.fromJson(Map<String, dynamic> json) {
    return OrganizationPlayerOrganization(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      logoUrl: json['logo_url']?.toString() ?? '',
    );
  }
}

class OrganizationPlayerPersonal {
  final String email;
  final String phone;
  final String birthdate;
  final String birthPlace;
  final String curp;
  final String address;
  final String cp;
  final String city;
  final String state;

  const OrganizationPlayerPersonal({
    required this.email,
    required this.phone,
    required this.birthdate,
    required this.birthPlace,
    required this.curp,
    required this.address,
    required this.cp,
    required this.city,
    required this.state,
  });

  factory OrganizationPlayerPersonal.fromJson(Map<String, dynamic> json) {
    return OrganizationPlayerPersonal(
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      birthdate: json['birthdate']?.toString() ?? '',
      birthPlace: json['birth_place']?.toString() ?? '',
      curp: json['curp']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      cp: json['cp']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
    );
  }
}

class OrganizationPlayerSport {
  final String position;
  final int? positionId;
  final String positionCatalogName;
  final String sizeShirt;
  final String sizePants;
  final String talla;
  final double? peso;
  final String bloodType;

  const OrganizationPlayerSport({
    required this.position,
    required this.positionId,
    required this.positionCatalogName,
    required this.sizeShirt,
    required this.sizePants,
    required this.talla,
    required this.peso,
    required this.bloodType,
  });

  factory OrganizationPlayerSport.fromJson(Map<String, dynamic> json) {
    return OrganizationPlayerSport(
      position: json['position']?.toString() ?? '',
      positionId: _toNullableInt(json['position_id']),
      positionCatalogName: json['position_catalog_name']?.toString() ?? '',
      sizeShirt: json['size_shirt']?.toString() ?? '',
      sizePants: json['size_pants']?.toString() ?? '',
      talla: json['talla']?.toString() ?? '',
      peso: _toNullableDouble(json['peso']),
      bloodType: json['blood_type']?.toString() ?? '',
    );
  }
}

class OrganizationPlayerHealth {
  final String allergies;
  final bool haveInsurance;
  final String insuranceName;
  final bool hasPlayedInFademac;
  final String fademacTeamName;
  final String interestArea;

  const OrganizationPlayerHealth({
    required this.allergies,
    required this.haveInsurance,
    required this.insuranceName,
    required this.hasPlayedInFademac,
    required this.fademacTeamName,
    required this.interestArea,
  });

  factory OrganizationPlayerHealth.fromJson(Map<String, dynamic> json) {
    return OrganizationPlayerHealth(
      allergies: json['allergies']?.toString() ?? '',
      haveInsurance: json['have_insurance'] == true,
      insuranceName: json['insurance_name']?.toString() ?? '',
      hasPlayedInFademac: json['has_played_in_fademac'] == true,
      fademacTeamName: json['fademac_team_name']?.toString() ?? '',
      interestArea: json['interest_area']?.toString() ?? '',
    );
  }
}

class OrganizationPlayerFamily {
  final OrganizationPlayerContact father;
  final OrganizationPlayerContact mother;

  const OrganizationPlayerFamily({required this.father, required this.mother});

  factory OrganizationPlayerFamily.fromJson(Map<String, dynamic> json) {
    return OrganizationPlayerFamily(
      father: OrganizationPlayerContact.fromJson(_asMap(json['father'])),
      mother: OrganizationPlayerContact.fromJson(_asMap(json['mother'])),
    );
  }
}

class OrganizationPlayerContact {
  final String name;
  final String email;
  final String phone;

  const OrganizationPlayerContact({
    required this.name,
    required this.email,
    required this.phone,
  });

  factory OrganizationPlayerContact.fromJson(Map<String, dynamic> json) {
    return OrganizationPlayerContact(
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
    );
  }
}

class OrganizationPlayerCategoryAssignment {
  final int id;
  final String name;
  final String slug;
  final int? jerseyNumber;
  final bool isCaptain;
  final String status;
  final DateTime? assignedAt;

  const OrganizationPlayerCategoryAssignment({
    required this.id,
    required this.name,
    required this.slug,
    required this.jerseyNumber,
    required this.isCaptain,
    required this.status,
    required this.assignedAt,
  });

  factory OrganizationPlayerCategoryAssignment.fromJson(
    Map<String, dynamic> json,
  ) {
    return OrganizationPlayerCategoryAssignment(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      jerseyNumber: _toNullableInt(json['jersey_number']),
      isCaptain: json['is_captain'] == true,
      status: json['status']?.toString() ?? '',
      assignedAt: _parseDate(json['assigned_at']),
    );
  }
}

class OrganizationPlayerDocuments {
  final OrganizationPlayerDocumentsSummary summary;
  final List<OrganizationPlayerDocumentRequirement> requirements;
  final List<OrganizationPlayerUploadedDocument> extraDocuments;

  const OrganizationPlayerDocuments({
    required this.summary,
    required this.requirements,
    required this.extraDocuments,
  });

  factory OrganizationPlayerDocuments.fromJson(Map<String, dynamic> json) {
    return OrganizationPlayerDocuments(
      summary: OrganizationPlayerDocumentsSummary.fromJson(
        _asMap(json['summary']),
      ),
      requirements: _asList(json['requirements'])
          .map(OrganizationPlayerDocumentRequirement.fromJson)
          .toList(),
      extraDocuments: _asList(json['extra_documents'])
          .map(OrganizationPlayerUploadedDocument.fromJson)
          .toList(),
    );
  }
}

class OrganizationPlayerDocumentsSummary {
  final int requiredTotal;
  final int requiredCompleted;
  final int requiredPending;
  final double completionRatio;
  final int uploadedTotal;

  const OrganizationPlayerDocumentsSummary({
    required this.requiredTotal,
    required this.requiredCompleted,
    required this.requiredPending,
    required this.completionRatio,
    required this.uploadedTotal,
  });

  factory OrganizationPlayerDocumentsSummary.fromJson(
      Map<String, dynamic> json) {
    return OrganizationPlayerDocumentsSummary(
      requiredTotal: _toInt(json['required_total']),
      requiredCompleted: _toInt(json['required_completed']),
      requiredPending: _toInt(json['required_pending']),
      completionRatio: _toDouble(json['completion_ratio']),
      uploadedTotal: _toInt(json['uploaded_total']),
    );
  }
}

class OrganizationPlayerDocumentRequirement {
  final int id;
  final String name;
  final String slug;
  final String description;
  final bool isRequired;
  final bool isActive;
  final int sortOrder;
  final int? expiresInDays;
  final bool isUploaded;
  final OrganizationPlayerUploadedDocument? document;

  const OrganizationPlayerDocumentRequirement({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.isRequired,
    required this.isActive,
    required this.sortOrder,
    required this.expiresInDays,
    required this.isUploaded,
    required this.document,
  });

  factory OrganizationPlayerDocumentRequirement.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawDocument = json['document'];
    return OrganizationPlayerDocumentRequirement(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      isRequired: json['is_required'] == true,
      isActive: json['is_active'] == true,
      sortOrder: _toInt(json['sort_order']),
      expiresInDays: _toNullableInt(json['expires_in_days']),
      isUploaded: json['is_uploaded'] == true,
      document: rawDocument is Map
          ? OrganizationPlayerUploadedDocument.fromJson(
              Map<String, dynamic>.from(rawDocument),
            )
          : null,
    );
  }
}

class OrganizationPlayerUploadedDocument {
  final int id;
  final int? requiredDocumentId;
  final String requiredDocumentName;
  final String requiredDocumentSlug;
  final String originalName;
  final String mimeType;
  final int size;
  final String url;
  final DateTime? uploadedAt;

  const OrganizationPlayerUploadedDocument({
    required this.id,
    required this.requiredDocumentId,
    required this.requiredDocumentName,
    required this.requiredDocumentSlug,
    required this.originalName,
    required this.mimeType,
    required this.size,
    required this.url,
    required this.uploadedAt,
  });

  factory OrganizationPlayerUploadedDocument.fromJson(
    Map<String, dynamic> json,
  ) {
    return OrganizationPlayerUploadedDocument(
      id: _toInt(json['id']),
      requiredDocumentId: _toNullableInt(json['required_document_id']),
      requiredDocumentName: json['required_document_name']?.toString() ?? '',
      requiredDocumentSlug: json['required_document_slug']?.toString() ?? '',
      originalName: json['original_name']?.toString() ?? '',
      mimeType: json['mime_type']?.toString() ?? '',
      size: _toInt(json['size']),
      url: json['url']?.toString() ?? '',
      uploadedAt: _parseDate(json['uploaded_at']),
    );
  }
}

class OrganizationPlayerPayments {
  final OrganizationPlayerPaymentsSummary summary;
  final List<OrganizationPlayerRecentPayment> recent;

  const OrganizationPlayerPayments({
    required this.summary,
    required this.recent,
  });

  factory OrganizationPlayerPayments.fromJson(Map<String, dynamic> json) {
    return OrganizationPlayerPayments(
      summary: OrganizationPlayerPaymentsSummary.fromJson(
        _asMap(json['summary']),
      ),
      recent: _asList(json['recent'])
          .map(OrganizationPlayerRecentPayment.fromJson)
          .toList(),
    );
  }
}

class OrganizationPlayerPaymentsSummary {
  final int totalCount;
  final int pendingCount;
  final int partialCount;
  final int paidCount;
  final double totalDue;
  final double totalPaid;
  final double totalBalance;

  const OrganizationPlayerPaymentsSummary({
    required this.totalCount,
    required this.pendingCount,
    required this.partialCount,
    required this.paidCount,
    required this.totalDue,
    required this.totalPaid,
    required this.totalBalance,
  });

  factory OrganizationPlayerPaymentsSummary.fromJson(
      Map<String, dynamic> json) {
    return OrganizationPlayerPaymentsSummary(
      totalCount: _toInt(json['total_count']),
      pendingCount: _toInt(json['pending_count']),
      partialCount: _toInt(json['partial_count']),
      paidCount: _toInt(json['paid_count']),
      totalDue: _toDouble(json['total_due']),
      totalPaid: _toDouble(json['total_paid']),
      totalBalance: _toDouble(json['total_balance']),
    );
  }
}

class OrganizationPlayerRecentPayment {
  final int id;
  final String concept;
  final String status;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final OrganizationPlayerPaymentCategory? category;
  final double amount;
  final double totalDue;
  final double amountPaid;
  final double balance;

  const OrganizationPlayerRecentPayment({
    required this.id,
    required this.concept,
    required this.status,
    required this.dueDate,
    required this.paidAt,
    required this.category,
    required this.amount,
    required this.totalDue,
    required this.amountPaid,
    required this.balance,
  });

  factory OrganizationPlayerRecentPayment.fromJson(Map<String, dynamic> json) {
    final rawCategory = json['category'];
    return OrganizationPlayerRecentPayment(
      id: _toInt(json['id']),
      concept: json['concept']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      dueDate: _parseDate(json['due_date']),
      paidAt: _parseDate(json['paid_at']),
      category: rawCategory is Map
          ? OrganizationPlayerPaymentCategory.fromJson(
              Map<String, dynamic>.from(rawCategory),
            )
          : null,
      amount: _toDouble(json['amount']),
      totalDue: _toDouble(json['total_due']),
      amountPaid: _toDouble(json['amount_paid']),
      balance: _toDouble(json['balance']),
    );
  }
}

class OrganizationPlayerPaymentCategory {
  final int id;
  final String name;
  final String slug;

  const OrganizationPlayerPaymentCategory({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory OrganizationPlayerPaymentCategory.fromJson(
      Map<String, dynamic> json) {
    return OrganizationPlayerPaymentCategory(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

List<Map<String, dynamic>> _asList(dynamic value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _toNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _toNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime? _parseDate(dynamic value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}
