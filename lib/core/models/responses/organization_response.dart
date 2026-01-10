class OrganizationResponse {
  final int id;
  final String name;
  final String slug;
  final String logo;
  final String primaryColor;
  final String secondaryColor;

  // Flags
  final bool isActive;
  final bool isEcommerceAvailable;

  // Ecommerce
  final EcommerceConfig ecommerce;

  // Apps
  final String? androidUrl;
  final String? iosUrl;

  OrganizationResponse({
    required this.id,
    required this.name,
    required this.slug,
    required this.logo,
    required this.primaryColor,
    required this.secondaryColor,
    required this.isActive,
    required this.isEcommerceAvailable,
    required this.ecommerce,
    this.androidUrl,
    this.iosUrl,
  });

  factory OrganizationResponse.fromJson(Map<String, dynamic> json) {
    return OrganizationResponse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      logo: json['logo'] ?? '',
      primaryColor: json['primary_color'] ?? '#000000',
      secondaryColor: json['secondary_color'] ?? '#FFFFFF',

      // Flags
      isActive: json['is_active'] ?? true,
      isEcommerceAvailable: json['is_ecommerce_available'] ?? false,

      // Ecommerce
      ecommerce: EcommerceConfig.fromJson(json['ecommerce'] ?? const {}),

      // Apps
      androidUrl: json['android_url'],
      iosUrl: json['ios_url'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'logo': logo,
    'primary_color': primaryColor,
    'secondary_color': secondaryColor,
    'is_active': isActive,
    'is_ecommerce_available': isEcommerceAvailable,
    'ecommerce': ecommerce.toJson(),
    'android_url': androidUrl,
    'ios_url': iosUrl,
  };
}

class EcommerceConfig {
  final bool enabled;
  final String currency;
  final bool pickupEnabled;
  final bool deliveryEnabled;
  final int deliveryFeeCents;
  final int minOrderCents;

  const EcommerceConfig({
    required this.enabled,
    required this.currency,
    required this.pickupEnabled,
    required this.deliveryEnabled,
    required this.deliveryFeeCents,
    required this.minOrderCents,
  });

  factory EcommerceConfig.fromJson(Map<String, dynamic> json) {
    return EcommerceConfig(
      enabled: json['enabled'] ?? false,
      currency: json['currency'] ?? 'MXN',
      pickupEnabled: json['pickup_enabled'] ?? true,
      deliveryEnabled: json['delivery_enabled'] ?? false,
      deliveryFeeCents: json['delivery_fee_cents'] ?? 0,
      minOrderCents: json['min_order_cents'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'currency': currency,
    'pickup_enabled': pickupEnabled,
    'delivery_enabled': deliveryEnabled,
    'delivery_fee_cents': deliveryFeeCents,
    'min_order_cents': minOrderCents,
  };

  /// Helpers útiles
  bool get hasDelivery => enabled && deliveryEnabled;
  bool get hasPickup => enabled && pickupEnabled;
}
