class LoginResponse {
  final User user;
  final Organization organization;
  final String tokenType;
  final String accessToken;
  final int accessExpiresInMinutes;
  final String refreshToken;
  final DateTime refreshExpiresAt;

  LoginResponse({
    required this.user,
    required this.organization,
    required this.tokenType,
    required this.accessToken,
    required this.accessExpiresInMinutes,
    required this.refreshToken,
    required this.refreshExpiresAt,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      user: User.fromJson(json['user'] ?? {}),
      organization: Organization.fromJson(json['organization'] ?? {}),
      tokenType: json['token_type'] ?? '',
      accessToken: json['access_token'] ?? '',
      accessExpiresInMinutes: json['access_expires_in_minutes'] ?? 0,
      refreshToken: json['refresh_token'] ?? '',
      refreshExpiresAt:
          DateTime.tryParse(json['refresh_expires_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class User {
  final int id;
  final String name;
  final String email;
  final String? photoUrl;
  final String role;
  final List<String> roles;
  final String primaryRole;
  final String activeRole;
  final String? so;
  final String? deviceToken;
  final String? deviceName;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.role,
    required this.roles,
    required this.primaryRole,
    required this.activeRole,
    this.so,
    this.deviceToken,
    this.deviceName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final parsedRoles = (json['roles'] is List)
        ? (json['roles'] as List)
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList()
        : <String>[];

    final roleFromApi = (json['role'] ?? '').toString();
    final primaryRole = (json['primary_role'] ?? '').toString();
    final activeRole = (json['active_role'] ?? '').toString();

    final effectiveRole = activeRole.isNotEmpty
        ? activeRole
        : (roleFromApi.isNotEmpty
              ? roleFromApi
              : (primaryRole.isNotEmpty ? primaryRole : ''));

    final roles = parsedRoles.isNotEmpty
        ? parsedRoles
        : (effectiveRole.isNotEmpty ? <String>[effectiveRole] : <String>[]);

    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      photoUrl: json['profile_photo_url'] ?? '',
      role: effectiveRole,
      roles: roles,
      primaryRole: primaryRole.isNotEmpty ? primaryRole : effectiveRole,
      activeRole: effectiveRole,
      so: json['so'],
      deviceToken: json['device_token'],
      deviceName: json['device_name'],
    );
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? photoUrl,
    String? role,
    List<String>? roles,
    String? primaryRole,
    String? activeRole,
    String? so,
    String? deviceToken,
    String? deviceName,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      roles: roles ?? this.roles,
      primaryRole: primaryRole ?? this.primaryRole,
      activeRole: activeRole ?? this.activeRole,
      so: so ?? this.so,
      deviceToken: deviceToken ?? this.deviceToken,
      deviceName: deviceName ?? this.deviceName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    if (photoUrl != null && photoUrl!.isNotEmpty) 'photo_url': photoUrl,
    'role': role,
    'roles': roles,
    'primary_role': primaryRole,
    'active_role': activeRole,
    if (so != null) 'so': so,
    if (deviceToken != null) 'device_token': deviceToken,
    if (deviceName != null) 'device_name': deviceName,
  };
}

class Organization {
  final int id;
  final String name;
  final String slug;
  final String logoUrl;
  final String primaryColor;
  final String secondaryColor;

  Organization({
    required this.id,
    required this.name,
    required this.slug,
    required this.logoUrl,
    required this.primaryColor,
    required this.secondaryColor,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      logoUrl: json['logo_url'] ?? '',
      primaryColor: json['primary_color'] ?? '',
      secondaryColor: json['secondary_color'] ?? '',
    );
  }
}
