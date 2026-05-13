import 'package:stopandgo/core/models/ecommerce/product_variant_model.dart';

class ProductDetailModel {
  static const String _storageBaseUrl = 'https://stopandgomx.app/storage/';

  final int id;
  final String name;
  final String? description;
  final String? imagePath;

  final List<ProductVariantListModel> variants;
  final List<ProductAttributeGroupModel> attributeGroups;
  final List<ProductVariantListModel> variantMatrix;

  ProductDetailModel({
    required this.id,
    required this.name,
    this.description,
    this.imagePath,
    required this.variants,
    required this.attributeGroups,
    required this.variantMatrix,
  });

  String? get imageUrl {
    if (imagePath == null || imagePath!.isEmpty) return null;
    if (imagePath!.startsWith('http')) return imagePath;
    return '$_storageBaseUrl$imagePath';
  }

  factory ProductDetailModel.fromApiResponse(Map<String, dynamic> json) {
    final data = (json['data'] is Map)
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;

    final variantsJson =
        (data['active_variants'] as List?) ??
        (data['variants'] as List?) ??
        const [];
    final attributeGroupsJson = (json['attribute_groups'] as List?) ?? const [];
    final variantMatrixJson = (json['variant_matrix'] as List?) ?? const [];

    return ProductDetailModel(
      id: (data['id'] as num).toInt(),
      name: (data['name'] ?? '') as String,
      description: data['description'] as String?,
      imagePath: data['image_path'] as String?,
      variants: variantsJson
          .map(
            (e) => ProductVariantListModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      attributeGroups: attributeGroupsJson
          .map(
            (e) => ProductAttributeGroupModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      variantMatrix: variantMatrixJson
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
    'attribute_groups': attributeGroups.map((g) => g.toJson()).toList(),
    'variant_matrix': variantMatrix.map((v) => v.toJson()).toList(),
  };
}

class ProductAttributeGroupModel {
  final int id;
  final String name;
  final List<ProductAttributeValueModel> values;

  ProductAttributeGroupModel({
    required this.id,
    required this.name,
    required this.values,
  });

  factory ProductAttributeGroupModel.fromJson(Map<String, dynamic> json) {
    final valuesJson = (json['values'] as List?) ?? const [];
    return ProductAttributeGroupModel(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '') as String,
      values: valuesJson
          .map(
            (e) => ProductAttributeValueModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'values': values.map((v) => v.toJson()).toList(),
  };
}

class ProductAttributeValueModel {
  final int id;
  final String value;
  final String label;

  ProductAttributeValueModel({
    required this.id,
    required this.value,
    required this.label,
  });

  factory ProductAttributeValueModel.fromJson(Map<String, dynamic> json) {
    return ProductAttributeValueModel(
      id: (json['id'] as num).toInt(),
      value: (json['value'] ?? '') as String,
      label: ((json['label'] ?? json['value']) ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'value': value,
    'label': label,
  };
}
