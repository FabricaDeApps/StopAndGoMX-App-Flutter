class CartItemVariantModel {
  final String? imagePath;

  CartItemVariantModel({this.imagePath});

  factory CartItemVariantModel.fromJson(Map<String, dynamic> json) {
    return CartItemVariantModel(imagePath: json['image_path']?.toString());
  }

  String? get imageUrl {
    final p = imagePath;
    if (p == null || p.isEmpty) return null;
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    return 'https://stopandgomx.app/storage/$p';
  }
}
