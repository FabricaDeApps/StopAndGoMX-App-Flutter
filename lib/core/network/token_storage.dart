import 'package:get_storage/get_storage.dart';

class TokenStorage extends GetxService {
  static const _keyAccess = 'access_token';
  static const _keyRefresh = 'refresh_token';
  static const _keyType = 'token_type';
  static const _keyAccessTtl = 'access_ttl';
  static const _keyRefreshExp = 'refresh_expires_at';

  final _box = GetStorage();

  String? get accessToken => _box.read<String?>(_keyAccess);
  String? get refreshToken => _box.read<String?>(_keyRefresh);
  String? get tokenType => _box.read<String?>(_keyType);

  /// Guarda sesión completa (al hacer login)
  Future<void> setSession({
    required String accessToken,
    required String tokenType,
    required String refreshToken,
  }) async {
    await _box.write(_keyAccess, accessToken);
    await _box.write(_keyRefresh, refreshToken);
    await _box.write(_keyType, tokenType);
  }

  /// 🔹 Actualiza solo el access token (tras refresh)
  Future<void> updateAccess({
    required String accessToken,
    required int accessTtlMinutes,
  }) async {
    await _box.write(_keyAccess, accessToken);
    await _box.write(_keyAccessTtl, accessTtlMinutes);
  }

  /// Limpia toda la sesión
  void clear() {
    _box.remove(_keyAccess);
    _box.remove(_keyRefresh);
    _box.remove(_keyType);
    _box.remove(_keyAccessTtl);
    _box.remove(_keyRefreshExp);
  }

  Future<TokenStorage> init() async => this;
}

class GetxService {}
