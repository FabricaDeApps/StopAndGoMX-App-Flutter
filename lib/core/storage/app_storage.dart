import 'package:get_storage/get_storage.dart';
import 'package:stopandgo/core/models/responses/organization_response.dart';
import 'package:stopandgo/core/models/responses/login_response.dart' show User;

class AppStorage {
  static const _boxName = 'app_storage';
  static late GetStorage _box;

  // 🔑 Claves usadas en el storage
  static const keyPrimary = 'primary_color';
  static const keySecondary = 'secondary_color';
  static const keySplashUrl = 'splash_url';
  static const keyOrganization = 'organization';
  static const keyUser = 'user';
  static const keySelectedCategoryId = 'selected_category_id';
  static const keySelectedCategoryName = 'selected_category_name';
  static const keySelectedPlayerId = 'selected_player_id';
  static const keySelectedPlayerName = 'selected_player_name';
  static const keyTokenDevice = 'key_token_device';
  static const keyPendingOrganizationId = 'pending_organization_id';
  static const keyAppUsageSession = 'app_usage_session';
  static const keyLastSeenAnnouncementId = 'last_seen_announcement_id';
  static const keyLastSeenBillingPauseSignature =
      'last_seen_billing_pause_signature';

  /// Inicialización
  static Future<void> init() async {
    await GetStorage.init(_boxName);
    _box = GetStorage(_boxName);
  }

  // 🔹 Getters convenientes
  static String? get primaryHex => _box.read<String?>(keyPrimary);
  static String? get secondaryHex => _box.read<String?>(keySecondary);
  static String? get splashUrl => _box.read<String?>(keySplashUrl);

  // ---------- USER ----------
  static Future<void> setUser(User user) async {
    await _box.write(keyUser, user.toJson());
  }

  static User? getUser() {
    final data = _box.read(keyUser);
    if (data == null) return null;
    return User.fromJson(Map<String, dynamic>.from(data));
  }

  static String? getActiveRole() {
    final user = getUser();
    if (user == null) return null;
    return user.activeRole.isNotEmpty ? user.activeRole : user.role;
  }

  static List<String> getAvailableRoles() {
    final user = getUser();
    if (user == null) return <String>[];
    return user.roles;
  }

  static Future<void> setActiveRole(String role) async {
    final trimmed = role.trim();
    if (trimmed.isEmpty) return;

    final user = getUser();
    if (user == null) return;

    final roles = user.roles.contains(trimmed)
        ? user.roles
        : <String>[...user.roles, trimmed];

    final updated = user.copyWith(
      role: trimmed,
      activeRole: trimmed,
      roles: roles,
      primaryRole: user.primaryRole.isNotEmpty ? user.primaryRole : trimmed,
    );

    await setUser(updated);
  }

  static Future<void> clearUser() async {
    await _box.remove(keyUser);
  }

  // ---------- ORGANIZATION + BRANDING ----------
  static Future<void> setBranding({
    required String primaryHex,
    required String secondaryHex,
    required String splashUrl,
  }) async {
    await _box.write(keyPrimary, primaryHex);
    await _box.write(keySecondary, secondaryHex);
    await _box.write(keySplashUrl, splashUrl);
  }

  static Future<void> setOrganization(OrganizationResponse org) async {
    await _box.write(keyOrganization, org.toJson());
    // Actualiza branding automáticamente:
    await setBranding(
      primaryHex: org.primaryColor,
      secondaryHex: org.secondaryColor,
      splashUrl: org.logo,
    );
  }

  static OrganizationResponse? getOrganization() {
    final data = _box.read(keyOrganization);
    if (data == null) return null;
    return OrganizationResponse.fromJson(Map<String, dynamic>.from(data));
  }

  /// Guarda el ID de la categoría seleccionada (para managers)
  static Future<void> setSelectedCategoryId(int? id) async {
    if (id == null) {
      await _box.remove(keySelectedCategoryId);
    } else {
      await _box.write(keySelectedCategoryId, id);
    }
  }

  static Future<void> setSelectedCategoryName(String? name) async {
    if (name == null) {
      await _box.remove(keySelectedCategoryName);
    } else {
      await _box.write(keySelectedCategoryName, name);
    }
  }

  static Future<void> setTokenDevice(String? value) async {
    if (value == null) {
      await _box.remove(keyTokenDevice);
    } else {
      await _box.write(keyTokenDevice, value);
    }
  }

  /// Obtiene el ID de la categoría seleccionada (si existe)
  static int? getSelectedCategoryId() {
    return _box.read<int?>(keySelectedCategoryId);
  }

  static String? getSelectedCategoryName() {
    return _box.read<String?>(keySelectedCategoryName);
  }

  static String? getTokenDevice() {
    return _box.read<String?>(keyTokenDevice);
  }

  static Future<void> setPendingOrganizationId(int? value) async {
    if (value == null || value <= 0) {
      await _box.remove(keyPendingOrganizationId);
      return;
    }
    await _box.write(keyPendingOrganizationId, value);
  }

  static int? getPendingOrganizationId() {
    return _box.read<int?>(keyPendingOrganizationId);
  }

  static Future<int?> consumePendingOrganizationId() async {
    final value = getPendingOrganizationId();
    await _box.remove(keyPendingOrganizationId);
    return value;
  }

  /// Guarda el ID del jugador seleccionado (para parent/player)
  static Future<void> setSelectedPlayerId(int? id) async {
    if (id == null) {
      await _box.remove(keySelectedPlayerId);
    } else {
      await _box.write(keySelectedPlayerId, id);
    }
  }

  /// Obtiene el ID del jugador seleccionado (si existe)
  static int? getSelectedPlayerId() {
    return _box.read<int?>(keySelectedPlayerId);
  }

  static Future<void> setSelectedPlayerName(String? value) async {
    if (value == null) {
      await _box.remove(keySelectedPlayerName);
    } else {
      await _box.write(keySelectedPlayerName, value);
    }
  }

  static String? getSelectedPlayerName() {
    return _box.read<String?>(keySelectedPlayerName);
  }

  static Future<void> clearOrganization() async {
    await _box.remove(keyOrganization);
    await _box.remove(keyPrimary);
    await _box.remove(keySecondary);
    await _box.remove(keySplashUrl);
  }

  static Future<void> setAppUsageSession(Map<String, dynamic>? session) async {
    if (session == null) {
      await _box.remove(keyAppUsageSession);
      return;
    }
    await _box.write(keyAppUsageSession, session);
  }

  static Map<String, dynamic>? getAppUsageSession() {
    final data = _box.read(keyAppUsageSession);
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  static Future<void> clearAppUsageSession() async {
    await _box.remove(keyAppUsageSession);
  }

  static Future<void> setLastSeenAnnouncementId(String? value) async {
    if (value == null || value.trim().isEmpty) {
      await _box.remove(keyLastSeenAnnouncementId);
      return;
    }
    await _box.write(keyLastSeenAnnouncementId, value.trim());
  }

  static String? getLastSeenAnnouncementId() {
    return _box.read<String?>(keyLastSeenAnnouncementId);
  }

  static Future<void> setLastSeenBillingPauseSignature(String? value) async {
    if (value == null || value.trim().isEmpty) {
      await _box.remove(keyLastSeenBillingPauseSignature);
      return;
    }
    await _box.write(keyLastSeenBillingPauseSignature, value.trim());
  }

  static String? getLastSeenBillingPauseSignature() {
    return _box.read<String?>(keyLastSeenBillingPauseSignature);
  }

  static Future<void> clearAll() async {
    await clearUser();
    await setPendingOrganizationId(null);
    await setSelectedCategoryId(null);
    await setSelectedCategoryName(null);
    await setSelectedPlayerId(null);
    await setSelectedPlayerName(null);
    await clearAppUsageSession();
  }
}
