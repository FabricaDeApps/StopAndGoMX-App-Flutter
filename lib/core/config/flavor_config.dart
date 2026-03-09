enum AppFlavor { main, zorros, raidersqro, wolverinesqro, bearsqro, redskins }

class FlavorConfig {
  final AppFlavor flavor;
  final String appName;
  final String bundleId;
  final bool isCustom;
  int? organizationId;
  final String? paymentProvider;

  static FlavorConfig? _instance;
  static FlavorConfig get I => _instance!;

  FlavorConfig._({
    required this.flavor,
    required this.appName,
    required this.bundleId,
    required this.isCustom,
    this.organizationId,
    this.paymentProvider,
  });

  static void init({
    required AppFlavor flavor,
    required String appName,
    required String bundleId,
    bool isCustom = false,
    int? organizationId,
    String? paymentProvider,
  }) {
    _instance = FlavorConfig._(
      flavor: flavor,
      appName: appName,
      bundleId: bundleId,
      isCustom: isCustom,
      organizationId: organizationId,
      paymentProvider: paymentProvider?.toLowerCase().trim(),
    );
  }

  bool get isZorros => flavor == AppFlavor.zorros;
  bool get isMain => flavor == AppFlavor.main;
  bool get isRaiders => flavor == AppFlavor.raidersqro;
  bool get isWolverines => flavor == AppFlavor.wolverinesqro;
  bool get isBears => flavor == AppFlavor.bearsqro;

  void updateOrganizationId(int newOrgId) {
    organizationId = newOrgId;
  }

  bool get hasPaymentProvider => paymentProvider != null;

  bool isPaymentProvider(String provider) =>
      paymentProvider == provider.toLowerCase().trim();

  // ------------------------------------------------------------
  // NUEVO: Permisos de tabs por flavor y rol
  // ------------------------------------------------------------
  static const Map<AppFlavor, Map<String, List<String>>> tabsByFlavorAndRole = {
    AppFlavor.main: {
      "parent": ["dashboard", "games", "payments", "notices", "gazzetta"],
      "player": ["dashboard", "games", "payments", "notices", "gazzetta"],
      "coach": ["dashboard", "games", "notices", "gazzetta"],
      "staff": ["dashboard", "games", "notices", "gazzetta"],
      "manager": ["dashboard", "games", "payments", "notices", "gazzetta"],
    },
    AppFlavor.zorros: {
      "parent": ["dashboard", "games", "payments", "notices", "gazzetta"],
      "player": ["dashboard", "games", "payments", "notices", "gazzetta"],
      "coach": ["dashboard", "games", "notices", "gazzetta"],
      "staff": ["dashboard", "games", "notices", "gazzetta"],
      "manager": ["dashboard", "games", "payments", "notices", "gazzetta"],
    },
    AppFlavor.raidersqro: {
      "parent": ["dashboard", "games", "payments", "notices", "gazzetta"],
      "player": ["dashboard", "games", "payments", "notices", "gazzetta"],
      "coach": ["dashboard", "games", "notices", "gazzetta"],
      "staff": ["dashboard", "games", "notices", "gazzetta"],
      "manager": ["dashboard", "games", "payments", "notices", "gazzetta"],
    },
    AppFlavor.wolverinesqro: {
      "parent": ["dashboard", "games", "payments", "notices", "gazzetta"],
      "player": ["dashboard", "games", "payments", "notices", "gazzetta"],
      "coach": ["dashboard", "games", "notices", "gazzetta"],
      "staff": ["dashboard", "games", "notices", "gazzetta"],
      "manager": ["dashboard", "games", "notices", "gazzetta"],
    },
    AppFlavor.bearsqro: {
      "parent": ["dashboard", "games", "payments", "notices", "gazzetta"],
      "player": ["dashboard", "games", "payments", "notices", "gazzetta"],
      "coach": ["dashboard", "games", "notices", "gazzetta"],
      "staff": ["dashboard", "games", "notices", "gazzetta"],
      "manager": ["dashboard", "games", "payments", "notices", "gazzetta"],
    },
    AppFlavor.redskins: {
      "parent": ["dashboard", "games", "payments", "notices", "gazzetta"],
      "player": ["dashboard", "games", "payments", "notices", "gazzetta"],
      "coach": ["dashboard", "games", "notices", "gazzetta"],
      "staff": ["dashboard", "games", "notices", "gazzetta"],
      "manager": ["dashboard", "games", "payments", "notices", "gazzetta"],
    },
  };

  /// Retorna los tabs habilitados según el rol
  List<String> getTabsForRole(String role) {
    return tabsByFlavorAndRole[flavor]?[role] ?? [];
  }
}
