class OrganizationResponse {
  final int id;
  final String name;
  final String slug;
  final String bankDetailsHtml;
  final String logo;
  final String primaryColor;
  final String secondaryColor;
  final bool billingPaused;
  final String? billingPauseStartsAt;
  final String? billingPauseEndsAt;
  final String? billingPauseReason;
  final String? subscriptionUiStatus;

  // Flags
  final bool isActive;

  /// Fuente compatible con cache viejo:
  /// - Si existe is_ecommerce_available -> lo respeta
  /// - Si NO existe -> cae a ecommerce.enabled
  final bool isEcommerceAvailable;
  final bool streamingEnabled;
  final bool payCardEnabled;
  final bool gazettaEnabled;
  final bool socialModule;
  final bool meritProgramEnabled;
  final List<OrganizationBanner> banners;

  // Ecommerce
  final EcommerceConfig ecommerce;

  // Apps
  final String? androidUrl;
  final String? iosUrl;
  final int? idVenueDefault;

  const OrganizationResponse({
    required this.id,
    required this.name,
    required this.slug,
    required this.bankDetailsHtml,
    required this.logo,
    required this.primaryColor,
    required this.secondaryColor,
    required this.billingPaused,
    this.billingPauseStartsAt,
    this.billingPauseEndsAt,
    this.billingPauseReason,
    this.subscriptionUiStatus,
    required this.isActive,
    required this.isEcommerceAvailable,
    required this.streamingEnabled,
    required this.payCardEnabled,
    required this.gazettaEnabled,
    required this.socialModule,
    required this.meritProgramEnabled,
    required this.banners,
    required this.ecommerce,
    this.androidUrl,
    this.iosUrl,
    this.idVenueDefault,
  });

  // ✅ Cast seguro para bool (GetStorage/GetBox a veces guarda 1/0 o "true"/"false")
  static bool _asBool(dynamic v, {required bool fallback}) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      if (['true', '1', 'yes', 'y', 'si', 'sí'].contains(s)) return true;
      if (['false', '0', 'no', 'n'].contains(s)) return false;
    }
    return fallback;
  }

  static int _asInt(dynamic v, {required int fallback}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return const <String, dynamic>{};
  }

  factory OrganizationResponse.fromJson(Map<String, dynamic> json) {
    final ecommerceMap = _asMap(json['ecommerce']);
    final ecommerce = EcommerceConfig.fromJson(ecommerceMap);
    final parsedBanners = (json['banners'] is List)
        ? (json['banners'] as List)
            .whereType<Map>()
            .map(
              (item) => OrganizationBanner.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
        : const <OrganizationBanner>[];

    // ✅ Si la key no existe (cache viejo), usa ecommerce.enabled
    final bool isEcomAvailable = json.containsKey('is_ecommerce_available')
        ? _asBool(json['is_ecommerce_available'], fallback: ecommerce.enabled)
        : ecommerce.enabled;

    return OrganizationResponse(
      id: _asInt(json['id'], fallback: 0),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      bankDetailsHtml: (json['bank_details_html'] ?? '').toString(),
      logo: (json['logo'] ?? '').toString(),
      primaryColor: (json['primary_color'] ?? '#000000').toString(),
      secondaryColor: (json['secondary_color'] ?? '#FFFFFF').toString(),
      billingPaused: _asBool(json['billing_paused'], fallback: false),
      billingPauseStartsAt: json['billing_pause_starts_at']?.toString(),
      billingPauseEndsAt: json['billing_pause_ends_at']?.toString(),
      billingPauseReason: json['billing_pause_reason']?.toString(),
      subscriptionUiStatus: json['subscription_ui_status']?.toString(),

      // Flags
      isActive: _asBool(json['is_active'], fallback: true),
      isEcommerceAvailable: isEcomAvailable,
      streamingEnabled: _asBool(json['streaming_enabled'], fallback: false),
      payCardEnabled: _asBool(json['pay_card_enabled'], fallback: false),
      gazettaEnabled: _asBool(
        json['gazetta_enabled'] ?? json['gazzetta_enabled'],
        fallback: false,
      ),
      socialModule: _asBool(json['social_module'], fallback: false),
      meritProgramEnabled: _asBool(
        json['merit_program_enabled'],
        fallback: false,
      ),
      banners: parsedBanners,

      // Ecommerce
      ecommerce: ecommerce,

      // Apps
      androidUrl: json['android_url']?.toString(),
      iosUrl: json['ios_url']?.toString(),
      idVenueDefault: json['id_venue_default'] == null
          ? null
          : _asInt(json['id_venue_default'], fallback: 0),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'bank_details_html': bankDetailsHtml,
        'logo': logo,
        'primary_color': primaryColor,
        'secondary_color': secondaryColor,
        'billing_paused': billingPaused,
        'billing_pause_starts_at': billingPauseStartsAt,
        'billing_pause_ends_at': billingPauseEndsAt,
        'billing_pause_reason': billingPauseReason,
        'subscription_ui_status': subscriptionUiStatus,
        'is_active': isActive,
        'is_ecommerce_available': isEcommerceAvailable,
        'streaming_enabled': streamingEnabled,
        'pay_card_enabled': payCardEnabled,
        'gazetta_enabled': gazettaEnabled,
        'social_module': socialModule,
        'merit_program_enabled': meritProgramEnabled,
        'banners': banners.map((item) => item.toJson()).toList(),
        'ecommerce': ecommerce.toJson(),
        'android_url': androidUrl,
        'ios_url': iosUrl,
        'id_venue_default': idVenueDefault,
      };

  /// Si quieres usar UNA sola fuente de verdad en UI, usa este getter:
  /// (aunque el flag exista, normalmente “available” = ecommerce.enabled)
  bool get ecommerceEnabled => ecommerce.enabled;

  bool get hasBillingPause => billingPaused || subscriptionUiStatus == 'paused';
}

class OrganizationBanner {
  final int id;
  final String imageUrl;
  final String title;
  final String subtitle;

  const OrganizationBanner({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
  });

  factory OrganizationBanner.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return OrganizationBanner(
      id: parseInt(json['id']),
      imageUrl: (json['image_url'] ?? json['url'] ?? '').toString().trim(),
      title: (json['title'] ?? '').toString().trim(),
      subtitle: (json['subtitle'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'image_url': imageUrl,
        'title': title,
        'subtitle': subtitle,
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

  static bool _asBool(dynamic v, {required bool fallback}) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      if (['true', '1', 'yes', 'y', 'si', 'sí'].contains(s)) return true;
      if (['false', '0', 'no', 'n'].contains(s)) return false;
    }
    return fallback;
  }

  static int _asInt(dynamic v, {required int fallback}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  factory EcommerceConfig.fromJson(Map<String, dynamic> json) {
    return EcommerceConfig(
      enabled: _asBool(json['enabled'], fallback: false),
      currency: (json['currency'] ?? 'MXN').toString(),
      pickupEnabled: _asBool(json['pickup_enabled'], fallback: true),
      deliveryEnabled: _asBool(json['delivery_enabled'], fallback: false),
      deliveryFeeCents: _asInt(json['delivery_fee_cents'], fallback: 0),
      minOrderCents: _asInt(json['min_order_cents'], fallback: 0),
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
