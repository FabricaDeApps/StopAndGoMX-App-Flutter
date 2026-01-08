import 'package:stopandgo/core/models/ecommerce/product_variant_model.dart';

class ProductDetailModel {
  static const String _storageBaseUrl = 'https://stopandgomx.app/storage/';

  final int id;
  final String name;
  final String? description;
  final String? imagePath;

  final List<ProductVariantListModel> variants;

  ProductDetailModel({
    required this.id,
    required this.name,
    this.description,
    this.imagePath,
    required this.variants,
  });

  String? get imageUrl {
    if (imagePath == null || imagePath!.isEmpty) return null;
    if (imagePath!.startsWith('http')) return imagePath;
    return '$_storageBaseUrl$imagePath';
  }

  factory ProductDetailModel.fromJson(Map<String, dynamic> json) {
    final variantsJson =
        (json['active_variants'] as List?) ??
        (json['variants'] as List?) ??
        const [];

    return ProductDetailModel(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '') as String,
      description: json['description'] as String?,
      imagePath: json['image_path'] as String?,
      variants: variantsJson
          .map(
            (e) => ProductVariantListModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'image_path': imagePath,
    'active_variants': variants.map((v) => v.toJson()).toList(),
  };
}
