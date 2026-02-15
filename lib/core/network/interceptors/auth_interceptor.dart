import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import 'package:stopandgo/core/network/auth_repository.dart';
import 'package:stopandgo/core/network/auth_service.dart';

import '../api_client.dart';
import '../token_storage.dart';

class AuthInterceptor extends Interceptor {
  final TokenStorage _storage = Get.find<TokenStorage>();
  final AuthRepository _authRepository = Get.find<AuthRepository>();

  bool _isAuthRoute(RequestOptions o) {
    final p = o.path;
    return p.contains('/auth/login') ||
        p.contains('/auth/refresh') ||
        p.contains('/auth/logout');
  }

  String _resolveTokenType() {
    final t = _storage.tokenType;
    if (t.trim().isNotEmpty) return t.trim();
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
      debugPrint('/auth request 401 -> no refresh token');
      await AuthService.forceLogout(reason: '401_without_refresh_token');
      return handler.next(err);
    }

    try {
      debugPrint('/auth request 401 -> trying refresh');
      final refreshed = await _authRepository.refreshIfNeeded();
      if (!refreshed) {
        await AuthService.forceLogout(reason: 'refresh_failed_after_401');
        return handler.next(err);
      }

      // Reintentar request original
      final response = await _retry(err.requestOptions);
      return handler.resolve(response);
    } catch (_) {
      await AuthService.forceLogout(reason: 'refresh_exception_after_401');
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
}
