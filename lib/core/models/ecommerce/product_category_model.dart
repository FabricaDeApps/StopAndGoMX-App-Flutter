class ProductCategoryModel {
  final int id;
  final String name;
  final String? image;
  final bool isActive;
  final int? order;

  ProductCategoryModel({
    required this.id,
    required this.name,
    this.image,
    required this.isActive,
    this.order,
  });

  factory ProductCategoryModel.fromJson(Map<String, dynamic> json) {
    return ProductCategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      image: json['image'] as String?,
      isActive: (json['is_active'] ?? true) as bool,
      order: json['order'] as int?,
    );
  }
}
