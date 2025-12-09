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
  static const keyTokenDevice = 'key_token_device';

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

  static Future<void> clearOrganization() async {
    await _box.remove(keyOrganization);
    await _box.remove(keyPrimary);
    await _box.remove(keySecondary);
    await _box.remove(keySplashUrl);
  }

  static Future<void> clearAll() async {
    await clearUser();
    await setSelectedCategoryId(null);
    await setSelectedCategoryName(null);
    await setSelectedPlayerId(null);
  }
}
