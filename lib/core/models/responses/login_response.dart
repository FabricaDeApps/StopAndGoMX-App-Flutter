import 'package:stopandgo/core/models/responses/organization_response.dart';

class LoginResponse {
  final User user;
  final OrganizationResponse organization;
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
      organization: OrganizationResponse.fromJson(
        _asMap(json['organization']),
      ),
      tokenType: json['token_type'] ?? '',
      accessToken: json['access_token'] ?? '',
      accessExpiresInMinutes: json['access_expires_in_minutes'] ?? 0,
      refreshToken: json['refresh_token'] ?? '',
      refreshExpiresAt:
          DateTime.tryParse(json['refresh_expires_at'] ?? '') ?? DateTime.now(),
    );
  }
}

Map<String, dynamic> _asMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return <String, dynamic>{};
}

class User {
  final int id;
  final String name;
  final String email;
  final String? photoUrl;
  final String? phone;
  final String? curp;
  final String? birthdate;
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
    this.phone,
    this.curp,
    this.birthdate,
    required this.role,
    required this.roles,
    required this.primaryRole,
    required this.activeRole,
    this.so,
    this.deviceToken,
    this.deviceName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    String normalizeRole(String? value) => (value ?? '').trim().toLowerCase();

    final parsedRoles = (json['roles'] is List)
        ? (json['roles'] as List)
            .map((e) => normalizeRole(e.toString()))
            .where((e) => e.isNotEmpty)
            .toList()
        : <String>[];

    final roleFromApi = normalizeRole((json['role'] ?? '').toString());
    final primaryRole = normalizeRole((json['primary_role'] ?? '').toString());
    final activeRole = normalizeRole((json['active_role'] ?? '').toString());

    final effectiveRole = activeRole.isNotEmpty
        ? activeRole
        : (roleFromApi.isNotEmpty
            ? roleFromApi
            : (primaryRole.isNotEmpty ? primaryRole : ''));

    final roles = parsedRoles.isNotEmpty
        ? parsedRoles
        : (effectiveRole.isNotEmpty ? <String>[effectiveRole] : <String>[]);
    final uniqueRoles = roles.toSet().toList();

    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      photoUrl: json['profile_photo_url']?.toString() ??
          json['photo_url']?.toString() ??
          '',
      phone: json['phone']?.toString(),
      curp: json['curp']?.toString(),
      birthdate: json['birthdate']?.toString() ??
          json['birth_date']?.toString() ??
          json['date_of_birth']?.toString(),
      role: effectiveRole,
      roles: uniqueRoles,
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
    String? phone,
    String? curp,
    String? birthdate,
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
      phone: phone ?? this.phone,
      curp: curp ?? this.curp,
      birthdate: birthdate ?? this.birthdate,
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
        if (photoUrl != null && photoUrl!.isNotEmpty) ...{
          'photo_url': photoUrl,
          'profile_photo_url': photoUrl,
        },
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
        if (curp != null && curp!.isNotEmpty) 'curp': curp,
        if (birthdate != null && birthdate!.isNotEmpty) 'birthdate': birthdate,
        'role': role,
        'roles': roles,
        'primary_role': primaryRole,
        'active_role': activeRole,
        if (so != null) 'so': so,
        if (deviceToken != null) 'device_token': deviceToken,
        if (deviceName != null) 'device_name': deviceName,
      };
}
