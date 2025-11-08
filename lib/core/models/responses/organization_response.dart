class OrganizationResponse {
  final int id;
  final String name;
  final String slug;
  final String logo;
  final String primaryColor;
  final String secondaryColor;

  OrganizationResponse({
    required this.id,
    required this.name,
    required this.slug,
    required this.logo,
    required this.primaryColor,
    required this.secondaryColor,
  });

  factory OrganizationResponse.fromJson(Map<String, dynamic> json) {
    return OrganizationResponse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      logo: json['logo'] ?? '',
      primaryColor: json['primary_color'] ?? '#000000',
      secondaryColor: json['secondary_color'] ?? '#FFFFFF',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'logo': logo,
    'primary_color': primaryColor,
    'secondary_color': secondaryColor,
  };
}
