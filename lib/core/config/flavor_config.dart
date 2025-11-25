enum AppFlavor { main, zorros, raidersqro }

class FlavorConfig {
  final AppFlavor flavor;
  final String appName;
  final String bundleId;
  int? organizationId;

  static FlavorConfig? _instance;
  static FlavorConfig get I => _instance!;

  FlavorConfig._({
    required this.flavor,
    required this.appName,
    required this.bundleId,
    this.organizationId,
  });

  static void init({
    required AppFlavor flavor,
    required String appName,
    required String bundleId,
    int? organizationId,
  }) {
    _instance = FlavorConfig._(
      flavor: flavor,
      appName: appName,
      bundleId: bundleId,
      organizationId: organizationId,
    );
  }

  bool get isZorros => flavor == AppFlavor.zorros;
  bool get isMain => flavor == AppFlavor.main;

  void updateOrganizationId(int newOrgId) {
    organizationId = newOrgId;
  }
}
