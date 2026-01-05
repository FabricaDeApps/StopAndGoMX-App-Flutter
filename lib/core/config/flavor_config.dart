enum AppFlavor { main, zorros, raidersqro, wolverinesqro, bearsqro }

class FlavorConfig {
  final AppFlavor flavor;
  final String appName;
  final String bundleId;
  int? organizationId;
  final String? paymentProvider;

  static FlavorConfig? _instance;
  static FlavorConfig get I => _instance!;

  FlavorConfig._({
    required this.flavor,
    required this.appName,
    required this.bundleId,
    this.organizationId,
    this.paymentProvider,
  });

  static void init({
    required AppFlavor flavor,
    required String appName,
    required String bundleId,
    int? organizationId,
    String? paymentProvider,
  }) {
    _instance = FlavorConfig._(
      flavor: flavor,
      appName: appName,
      bundleId: bundleId,
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
      "parent": ["dashboard", "games", "payments", "notices"],
      "player": ["dashboard", "games", "payments", "notices"],
      "coach": ["dashboard", "games", "notices"],
      "manager": ["dashboard", "games", "payments", "notices"],
    },
    AppFlavor.zorros: {
      "parent": ["dashboard", "games", "payments", "notices"],
      "player": ["dashboard", "games", "payments", "notices"],
      "coach": ["dashboard", "games", "notices"],
      "manager": ["dashboard", "games", "payments", "notices"],
    },
    AppFlavor.raidersqro: {
      "parent": ["dashboard", "games", "payments", "notices"],
      "player": ["dashboard", "games", "payments", "notices"],
      "coach": ["dashboard", "games", "notices"],
      "manager": ["dashboard", "games", "payments", "notices"],
    },
    AppFlavor.wolverinesqro: {
      "parent": ["dashboard", "games", "payments", "notices"],
      "player": ["dashboard", "games", "payments", "notices"],
      "coach": ["dashboard", "games", "notices"],
      "manager": ["dashboard", "games", "notices"],
    },
    AppFlavor.bearsqro: {
      "parent": ["dashboard", "games", "payments", "notices"],
      "player": ["dashboard", "games", "payments", "notices"],
      "coach": ["dashboard", "games", "notices"],
      "manager": ["dashboard", "games", "payments", "notices"],
    },
  };

  /// Retorna los tabs habilitados según el rol
  List<String> getTabsForRole(String role) {
    return tabsByFlavorAndRole[flavor]?[role] ?? [];
  }
}
