import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';

class TokenStorage extends GetxService {
  static const _keyAccess = 'access_token';
  static const _keyRefresh = 'refresh_token';
  static const _keyType = 'token_type';

  final _box = GetStorage();

  String? get accessToken => _box.read<String?>(_keyAccess);
  String? get refreshToken => _box.read<String?>(_keyRefresh);

  // ✅ default Bearer
  String get tokenType => (_box.read<String?>(_keyType) ?? 'Bearer');

  Future<void> setSession({
    required String accessToken,
    required String tokenType,
    required String refreshToken,
  }) async {
    await _box.write(_keyAccess, accessToken);
    await _box.write(_keyRefresh, refreshToken);
    await _box.write(_keyType, tokenType);
  }

  void clear() {
    _box.remove(_keyAccess);
    _box.remove(_keyRefresh);
    _box.remove(_keyType);
  }

  Future<TokenStorage> init() async => this;
}
