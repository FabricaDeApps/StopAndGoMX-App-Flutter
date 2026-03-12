import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';

class TokenStorage extends GetxService {
  static const _boxName = 'app_storage';
  static const _keyAccess = 'access_token';
  static const _keyRefresh = 'refresh_token';
  static const _keyType = 'token_type';
  static const _keyRefreshExpiresAt = 'refresh_expires_at';
  static const _keyAccessExpiresInMinutes = 'access_expires_in_minutes';
  static const _legacyKeyAccessTtl = 'access_ttl';

  late final GetStorage _box;

  String? get accessToken => _box.read<String?>(_keyAccess);
  String? get refreshToken => _box.read<String?>(_keyRefresh);
  DateTime? get refreshExpiresAt {
    final raw = _box.read<String?>(_keyRefreshExpiresAt);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  int? get accessExpiresInMinutes =>
      _box.read<int?>(_keyAccessExpiresInMinutes);
  bool get hasRefreshToken => (refreshToken ?? '').trim().isNotEmpty;

  // ✅ default Bearer
  String get tokenType {
    final value = (_box.read<String?>(_keyType) ?? 'Bearer').trim();
    return value.isEmpty ? 'Bearer' : value;
  }

  bool get isRefreshExpired {
    final exp = refreshExpiresAt;
    if (exp == null) return false;
    return DateTime.now().isAfter(exp);
  }

  Future<void> setSession({
    required String accessToken,
    required String tokenType,
    required String refreshToken,
    DateTime? refreshExpiresAt,
    int? accessExpiresInMinutes,
  }) async {
    await _box.write(_keyAccess, accessToken);
    await _box.write(_keyRefresh, refreshToken);
    await _box.write(_keyType, tokenType);
    if (refreshExpiresAt != null) {
      await _box.write(
        _keyRefreshExpiresAt,
        refreshExpiresAt.toIso8601String(),
      );
    }
    if (accessExpiresInMinutes != null) {
      await _box.write(_keyAccessExpiresInMinutes, accessExpiresInMinutes);
    }
  }

  Future<void> clear() async {
    await _box.remove(_keyAccess);
    await _box.remove(_keyRefresh);
    await _box.remove(_keyType);
    await _box.remove(_keyRefreshExpiresAt);
    await _box.remove(_keyAccessExpiresInMinutes);
  }

  Future<TokenStorage> init() async {
    await GetStorage.init(_boxName);
    _box = GetStorage(_boxName);
    await _migrateLegacyDefaultBoxIfNeeded();
    return this;
  }

  Future<void> _migrateLegacyDefaultBoxIfNeeded() async {
    final hasCurrentSession =
        (accessToken ?? '').trim().isNotEmpty ||
        (refreshToken ?? '').trim().isNotEmpty;
    if (hasCurrentSession) return;

    // Compatibilidad con builds anteriores que guardaban tokens
    // en la caja default de GetStorage (sin nombre).
    await GetStorage.init();
    final legacyBox = GetStorage();

    final legacyAccess = legacyBox.read<String?>(_keyAccess);
    final legacyRefresh = legacyBox.read<String?>(_keyRefresh);
    if ((legacyAccess ?? '').trim().isEmpty &&
        (legacyRefresh ?? '').trim().isEmpty) {
      return;
    }

    final legacyType = (legacyBox.read<String?>(_keyType) ?? 'Bearer').trim();
    final legacyRefreshExp = legacyBox.read<String?>(_keyRefreshExpiresAt);
    final legacyAccessTtl =
        legacyBox.read<int?>(_keyAccessExpiresInMinutes) ??
        legacyBox.read<int?>(_legacyKeyAccessTtl);

    await _box.write(_keyAccess, legacyAccess);
    await _box.write(_keyRefresh, legacyRefresh);
    await _box.write(_keyType, legacyType.isEmpty ? 'Bearer' : legacyType);

    if (legacyRefreshExp != null && legacyRefreshExp.trim().isNotEmpty) {
      await _box.write(_keyRefreshExpiresAt, legacyRefreshExp);
    }
    if (legacyAccessTtl != null) {
      await _box.write(_keyAccessExpiresInMinutes, legacyAccessTtl);
    }

    // Evita repetir migración en siguientes arranques.
    await legacyBox.remove(_keyAccess);
    await legacyBox.remove(_keyRefresh);
    await legacyBox.remove(_keyType);
    await legacyBox.remove(_keyRefreshExpiresAt);
    await legacyBox.remove(_keyAccessExpiresInMinutes);
    await legacyBox.remove(_legacyKeyAccessTtl);
  }
}
