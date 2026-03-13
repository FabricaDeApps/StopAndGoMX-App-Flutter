class AdminPlayerCategory {
  final int id;
  final String name;

  const AdminPlayerCategory({required this.id, required this.name});

  factory AdminPlayerCategory.fromJson(Map<String, dynamic> json) {
    return AdminPlayerCategory(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
    );
  }
}

class AdminPlayer {
  final int id;
  final int organizationId;
  final String? firstName;
  final String? lastName;
  final String? alias;
  final String displayName;
  final String? birthdate;
  final String? birthPlace;
  final String? curp;
  final String? position;
  final int? positionId;
  final String? positionCatalogName;
  final String? phone;
  final String? email;
  final String? address;
  final String? cp;
  final String? city;
  final String? state;
  final String? sizeShirt;
  final String? sizePants;
  final String? talla;
  final num? peso;
  final String? fatherName;
  final String? fatherEmail;
  final String? fatherPhone;
  final String? motherName;
  final String? motherEmail;
  final String? motherPhone;
  final String? interestArea;
  final String? bloodType;
  final bool haveInsurance;
  final String? insuranceName;
  final String? allergies;
  final String? photoUrl;
  final bool isActive;
  final bool confirmed;
  final bool archived;
  final List<AdminPlayerCategory> categories;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;

  const AdminPlayer({
    required this.id,
    required this.organizationId,
    required this.firstName,
    required this.lastName,
    required this.alias,
    required this.displayName,
    required this.birthdate,
    required this.birthPlace,
    required this.curp,
    required this.position,
    required this.positionId,
    required this.positionCatalogName,
    required this.phone,
    required this.email,
    required this.address,
    required this.cp,
    required this.city,
    required this.state,
    required this.sizeShirt,
    required this.sizePants,
    required this.talla,
    required this.peso,
    required this.fatherName,
    required this.fatherEmail,
    required this.fatherPhone,
    required this.motherName,
    required this.motherEmail,
    required this.motherPhone,
    required this.interestArea,
    required this.bloodType,
    required this.haveInsurance,
    required this.insuranceName,
    required this.allergies,
    required this.photoUrl,
    required this.isActive,
    required this.confirmed,
    required this.archived,
    required this.categories,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  factory AdminPlayer.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['categories'] as List? ?? const [];
    return AdminPlayer(
      id: (json['id'] as num?)?.toInt() ?? 0,
      organizationId: (json['organization_id'] as num?)?.toInt() ?? 0,
      firstName: _nullableString(json['first_name']),
      lastName: _nullableString(json['last_name']),
      alias: _nullableString(json['alias']),
      displayName: (json['display_name'] ?? '').toString(),
      birthdate: _nullableString(json['birthdate']),
      birthPlace: _nullableString(json['birth_place']),
      curp: _nullableString(json['curp']),
      position: _nullableString(json['position']),
      positionId: (json['position_id'] as num?)?.toInt(),
      positionCatalogName: _nullableString(json['position_catalog_name']),
      phone: _nullableString(json['phone']),
      email: _nullableString(json['email']),
      address: _nullableString(json['address']),
      cp: _nullableString(json['cp']),
      city: _nullableString(json['city']),
      state: _nullableString(json['state']),
      sizeShirt: _nullableString(json['size_shirt']),
      sizePants: _nullableString(json['size_pants']),
      talla: _nullableString(json['talla']),
      peso: json['peso'] as num?,
      fatherName: _nullableString(json['father_name']),
      fatherEmail: _nullableString(json['father_email']),
      fatherPhone: _nullableString(json['father_phone']),
      motherName: _nullableString(json['mother_name']),
      motherEmail: _nullableString(json['mother_email']),
      motherPhone: _nullableString(json['mother_phone']),
      interestArea: _nullableString(json['interest_area']),
      bloodType: _nullableString(json['blood_type']),
      haveInsurance: json['have_insurance'] == true,
      insuranceName: _nullableString(json['insurance_name']),
      allergies: _nullableString(json['allergies']),
      photoUrl: _nullableString(json['photo_url']),
      isActive: json['is_active'] == true,
      confirmed: json['confirmed'] == true,
      archived: json['archived'] == true,
      categories: rawCategories
          .whereType<Map>()
          .map((e) => AdminPlayerCategory.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      createdAt: _nullableString(json['created_at']),
      updatedAt: _nullableString(json['updated_at']),
      deletedAt: _nullableString(json['deleted_at']),
    );
  }
}

class AdminPlayersResponse {
  final List<AdminPlayer> data;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final String? nextPageUrl;
  final String? prevPageUrl;

  const AdminPlayersResponse({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.nextPageUrl,
    required this.prevPageUrl,
  });

  factory AdminPlayersResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] as List? ?? const [];
    final meta = Map<String, dynamic>.from(json['meta'] as Map? ?? const {});
    final links = Map<String, dynamic>.from(json['links'] as Map? ?? const {});

    return AdminPlayersResponse(
      data: rawData
          .whereType<Map>()
          .map((e) => AdminPlayer.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      currentPage: (meta['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
      perPage: (meta['per_page'] as num?)?.toInt() ?? 25,
      total: (meta['total'] as num?)?.toInt() ?? 0,
      nextPageUrl: _nullableString(links['next']),
      prevPageUrl: _nullableString(links['prev']),
    );
  }
}

String? _nullableString(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text == 'null') return null;
  return text;
}
