import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../api_client.dart';
import '../token_storage.dart';

class AuthInterceptor extends Interceptor {
  final _storage = Get.find<TokenStorage>();
  bool _isRefreshing = false; // evita bucles infinitos
  final List<Function(String)> _queuedRequests = [];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _storage.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Solo actuamos ante 401 no autorizados
    if (err.response?.statusCode == 401) {
      final refreshToken = _storage.refreshToken;
      if (refreshToken == null || refreshToken.isEmpty) {
        // No hay refresh token → logout
        _storage.clear();
        return handler.next(err);
      }

      // Si ya se está refrescando, espera en cola
      if (_isRefreshing) {
        _queuedRequests.add((newToken) async {
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final response = await ApiClient.dio.fetch(err.requestOptions);
          handler.resolve(response);
        });
        return;
      }

      _isRefreshing = true;

      try {
        // === Intentar refrescar token ===
        final dio = ApiClient.dio;
        final res = await dio.post(
          '/auth/refresh',
          data: {'refresh_token': refreshToken},
        );

        final newAccess = res.data['access_token'];
        final newRefresh = res.data['refresh_token'];
        final tokenType = res.data['token_type'] ?? 'Bearer';

        if (newAccess != null && newAccess.isNotEmpty) {
          await _storage.setSession(
            accessToken: newAccess,
            refreshToken: newRefresh,
            tokenType: tokenType,
          );

          // Reintenta la request original
          err.requestOptions.headers['Authorization'] = '$tokenType $newAccess';
          final response = await dio.fetch(err.requestOptions);

          // Ejecuta encolados
          for (final cb in _queuedRequests) {
            await cb(newAccess);
          }
          _queuedRequests.clear();

          _isRefreshing = false;
          return handler.resolve(response);
        } else {
          _storage.clear();
          _isRefreshing = false;
          return handler.next(err);
        }
      } catch (e) {
        _isRefreshing = false;
        _storage.clear();
        return handler.next(err);
      }
    }

    // No es 401 → pasa normal
    handler.next(err);
  }
}
