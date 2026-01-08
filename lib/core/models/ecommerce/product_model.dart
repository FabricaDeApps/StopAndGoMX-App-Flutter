import 'package:stopandgo/core/models/ecommerce/product_variant_model.dart';

class ProductModel {
  final int id;
  final String name;
  final String? description;
  final String? imagePath;

  final List<ProductVariantListModel> activeVariants;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    this.imagePath,
    required this.activeVariants,
  });

  static const String _storageBaseUrl = 'https://stopandgomx.app/storage/';

  String? get imageUrl {
    if (imagePath == null || imagePath!.isEmpty) return null;
    if (imagePath!.startsWith('http')) return imagePath;
    return '$_storageBaseUrl$imagePath';
  }

  int get variantsCount => activeVariants.length;

  int get minPriceCents {
    if (activeVariants.isEmpty) return 0;
    var min = activeVariants.first.priceCents;
    for (final v in activeVariants) {
      if (v.priceCents < min) min = v.priceCents;
    }
    return min;
  }

  double get minPrice => minPriceCents / 100.0;

  List<String> get previewValues {
    // toma los primeros valores de la primera variante (o mezcla)
    if (activeVariants.isEmpty) return const [];
    final vals = activeVariants.first.values;
    return vals.length > 3 ? vals.take(3).toList() : vals;
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final variantsJson = (json['active_variants'] as List?) ?? const [];
    return ProductModel(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '') as String,
      description: json['description'] as String?,
      imagePath: json['image_path'] as String?,
      activeVariants: variantsJson
          .map(
            (e) => ProductVariantListModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }
}
