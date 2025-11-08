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
  final String role;
  final String? so;
  final String? deviceToken;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.so,
    this.deviceToken,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      so: json['so'],
      deviceToken: json['device_token'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    if (so != null) 'so': so,
    if (deviceToken != null) 'device_token': deviceToken,
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
