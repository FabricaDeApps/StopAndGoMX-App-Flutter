class Category {
  final int id;
  final int? organizationId;
  final String name;
  final String? slug;
  final String? code;
  final String? ageRange;
  final String? description;
  final bool isActive;

  Category({
    required this.id,
    required this.name,
    this.organizationId,
    this.slug,
    this.code,
    this.ageRange,
    this.description,
    this.isActive = true,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as int,
    organizationId: json['organization_id'] != null
        ? json['organization_id'] as int
        : null,
    name: json['name'] as String,
    slug: json['slug'] as String?,
    code: json['code'] as String?,
    ageRange: json['age_range'] as String?,
    description: json['description'] as String?,
    isActive: (json['is_active'] ?? true) == true,
  );
}
