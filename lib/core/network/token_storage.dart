import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';

class TokenStorage extends GetxService {
  static const _boxName = 'app_storage';
  static const _keyAccess = 'access_token';
  static const _keyRefresh = 'refresh_token';
  static const _keyType = 'token_type';
  static const _keyRefreshExpiresAt = 'refresh_expires_at';
  static const _keyAccessExpiresInMinutes = 'access_expires_in_minutes';

  late final GetStorage _box;

  String? get accessToken => _box.read<String?>(_keyAccess);
  String? get refreshToken => _box.read<String?>(_keyRefresh);
  DateTime? get refreshExpiresAt {
    final raw = _box.read<String?>(_keyRefreshExpiresAt);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
  int? get accessExpiresInMinutes => _box.read<int?>(_keyAccessExpiresInMinutes);
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
      await _box.write(_keyRefreshExpiresAt, refreshExpiresAt.toIso8601String());
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
    return this;
  }
}
