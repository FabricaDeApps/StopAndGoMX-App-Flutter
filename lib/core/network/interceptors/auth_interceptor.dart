import 'dart:async';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:stopandgo/core/network/auth_service.dart';

import '../api_client.dart';
import '../token_storage.dart';

class AuthInterceptor extends Interceptor {
  final TokenStorage _storage = Get.find<TokenStorage>();

  bool _isRefreshing = false;
  final List<Completer<void>> _refreshWaiters = [];

  bool _isAuthRoute(RequestOptions o) {
    final p = o.path;
    return p.contains('/auth/login') ||
        p.contains('/auth/refresh') ||
        p.contains('/auth/logout') ||
        p.contains('/auth/me');
  }

  String _resolveTokenType() {
    final t = _storage.tokenType;
    if (t != null && t.trim().isNotEmpty) return t.trim();
    return 'Bearer';
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _storage.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = '${_resolveTokenType()} $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;

    // Solo actuamos en 401 y NO en endpoints de auth para evitar loops
    if (status != 401 || _isAuthRoute(err.requestOptions)) {
      return handler.next(err);
    }

    final refreshToken = _storage.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      await AuthService.forceLogout();
      return handler.next(err);
    }

    try {
      // Si ya hay refresh corriendo, nos colgamos a él
      if (_isRefreshing) {
        final waiter = Completer<void>();
        _refreshWaiters.add(waiter);

        try {
          await waiter.future;
        } catch (_) {}

        final newAccess = _storage.accessToken;
        if (newAccess == null || newAccess.isEmpty) {
          await AuthService.forceLogout();
          return handler.next(err);
        }

        final response = await _retry(err.requestOptions);
        return handler.resolve(response);
      }

      _isRefreshing = true;

      final refreshDio = Dio(
        BaseOptions(
          baseUrl: ApiClient.dio.options.baseUrl,
          connectTimeout: ApiClient.dio.options.connectTimeout,
          receiveTimeout: ApiClient.dio.options.receiveTimeout,
          sendTimeout: ApiClient.dio.options.sendTimeout,
          headers: {'Accept': 'application/json'},
        ),
      );

      final res = await refreshDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final data = res.data;
      final newAccess = (data is Map)
          ? (data['access_token']?.toString() ?? '')
          : '';
      final newRefresh = (data is Map)
          ? (data['refresh_token']?.toString() ?? '')
          : '';
      final tokenType = (data is Map)
          ? (data['token_type']?.toString() ?? 'Bearer')
          : 'Bearer';

      if (newAccess.isEmpty) {
        _completeWaitersWithError();
        _isRefreshing = false;

        // ✅ refresh respondió mal => logout + redirect login
        await AuthService.forceLogout();
        return handler.next(err);
      }

      // Guardar sesión actualizada
      await _storage.setSession(
        accessToken: newAccess,
        refreshToken: newRefresh.isNotEmpty ? newRefresh : refreshToken,
        tokenType: tokenType,
      );

      // Completar los que estaban esperando refresh
      _completeWaitersOk();
      _isRefreshing = false;

      // Reintentar request original
      final response = await _retry(err.requestOptions);
      return handler.resolve(response);
    } on DioException catch (e) {
      final payload = e.response?.data;
      final code = (payload is Map) ? payload['code']?.toString() : null;

      final mustLogout =
          code == 'USER_INACTIVE' ||
          code == 'REFRESH_EXPIRED' ||
          code == 'REFRESH_INVALID' ||
          code == 'USER_NOT_FOUND';

      _completeWaitersWithError();
      _isRefreshing = false;

      if (mustLogout) {
        // ✅ sesión no recuperable => logout + redirect login
        await AuthService.forceLogout();
      }

      return handler.next(err);
    } catch (_) {
      _completeWaitersWithError();
      _isRefreshing = false;

      // ✅ error inesperado => logout + redirect login
      await AuthService.forceLogout();
      return handler.next(err);
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final token = _storage.accessToken;
    final type = _resolveTokenType();

    final headers = Map<String, dynamic>.from(requestOptions.headers);
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = '$type $token';
    }

    final options = Options(
      method: requestOptions.method,
      headers: headers,
      responseType: requestOptions.responseType,
      contentType: requestOptions.contentType,
      followRedirects: requestOptions.followRedirects,
      validateStatus: requestOptions.validateStatus,
      receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
      sendTimeout: requestOptions.sendTimeout,
      receiveTimeout: requestOptions.receiveTimeout,
    );

    return ApiClient.dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  void _completeWaitersOk() {
    for (final w in _refreshWaiters) {
      if (!w.isCompleted) w.complete();
    }
    _refreshWaiters.clear();
  }

  void _completeWaitersWithError() {
    for (final w in _refreshWaiters) {
      if (!w.isCompleted) w.completeError('refresh_failed');
    }
    _refreshWaiters.clear();
  }
}
