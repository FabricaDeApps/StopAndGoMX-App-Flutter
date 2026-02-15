import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/constants/api_endpoints.dart';
import 'package:stopandgo/core/models/responses/login_response.dart';
import 'package:stopandgo/core/storage/app_storage.dart';

import 'api_client.dart';
import 'token_storage.dart';

class SessionRestoreResult {
  final bool isAuthenticated;
  final String reason;

  const SessionRestoreResult({
    required this.isAuthenticated,
    required this.reason,
  });
}

class AuthRepository extends GetxService {
  final Dio _dio = ApiClient.dio;
  final TokenStorage _tokenStorage = Get.find<TokenStorage>();

  Completer<bool>? _refreshCompleter;

  Future<SessionRestoreResult> restoreSession() async {
    final access = _tokenStorage.accessToken;
    final refresh = _tokenStorage.refreshToken;
    final hasUser = AppStorage.getUser() != null;

    debugPrint(
      'token loaded from storage access=${_mask(access)} refresh=${_mask(refresh)} '
      'refresh_exp=${_tokenStorage.refreshExpiresAt?.toIso8601String()} '
      'has_user=$hasUser',
    );

    if ((access == null || access.isEmpty) &&
        (refresh == null || refresh.isEmpty)) {
      return const SessionRestoreResult(
        isAuthenticated: false,
        reason: 'no_tokens_in_storage',
      );
    }

    final meResult = await _loadAuthMe();
    if (meResult == _AuthMeStatus.ok) {
      return const SessionRestoreResult(
        isAuthenticated: true,
        reason: 'auth_me_ok',
      );
    }

    if (meResult == _AuthMeStatus.otherError) {
      final canUseCache = AppStorage.getUser() != null;
      return SessionRestoreResult(
        isAuthenticated: canUseCache,
        reason: canUseCache
            ? 'auth_me_other_error_using_cached_user'
            : 'auth_me_other_error_without_cached_user',
      );
    }

    debugPrint('/auth/me 401 -> trying refresh');
    final refreshed = await refreshIfNeeded();
    if (!refreshed) {
      await logoutLocal();
      return const SessionRestoreResult(
        isAuthenticated: false,
        reason: 'refresh_failed',
      );
    }

    final meAfterRefresh = await _loadAuthMe();
    if (meAfterRefresh == _AuthMeStatus.ok) {
      return const SessionRestoreResult(
        isAuthenticated: true,
        reason: 'refresh_success_and_auth_me_ok',
      );
    }

    await logoutLocal();
    return const SessionRestoreResult(
      isAuthenticated: false,
      reason: 'auth_me_failed_after_refresh',
    );
  }

  Future<bool> refreshIfNeeded() async {
    final inFlight = _refreshCompleter;
    if (inFlight != null) return inFlight.future;

    final completer = Completer<bool>();
    _refreshCompleter = completer;

    try {
      final currentRefresh = _tokenStorage.refreshToken;
      if (currentRefresh == null || currentRefresh.isEmpty) {
        debugPrint('refresh fail: no refresh token');
        completer.complete(false);
        return false;
      }

      if (_tokenStorage.isRefreshExpired) {
        debugPrint('refresh fail: refresh token expired');
        completer.complete(false);
        return false;
      }

      final res = await _dio.post(
        ApiEndpoints.authRefresh,
        data: {'refresh_token': currentRefresh},
        options: Options(headers: {'Accept': 'application/json'}),
      );

      final payload = _asMap(res.data);
      final newAccess = payload['access_token']?.toString() ?? '';
      final newRefresh = payload['refresh_token']?.toString() ?? currentRefresh;
      final newType = payload['token_type']?.toString() ?? 'Bearer';
      final refreshExpRaw = payload['refresh_expires_at']?.toString();
      final refreshExp =
          (refreshExpRaw == null || refreshExpRaw.isEmpty)
              ? _tokenStorage.refreshExpiresAt
              : DateTime.tryParse(refreshExpRaw);
      final accessExpiresMinutes = _asInt(payload['access_expires_in_minutes']);

      if (newAccess.isEmpty) {
        debugPrint('refresh fail: empty access token in response');
        completer.complete(false);
        return false;
      }

      await _tokenStorage.setSession(
        accessToken: newAccess,
        refreshToken: newRefresh,
        tokenType: newType,
        refreshExpiresAt: refreshExp,
        accessExpiresInMinutes: accessExpiresMinutes,
      );
      debugPrint('refresh success');
      completer.complete(true);
      return true;
    } catch (e) {
      debugPrint('refresh fail: $e');
      completer.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<void> logoutLocal() async {
    await _tokenStorage.clear();
    await AppStorage.clearAll();
  }

  Future<_AuthMeStatus> _loadAuthMe() async {
    try {
      final res = await _dio.get(
        ApiEndpoints.authMe,
        options: Options(headers: {'Accept': 'application/json'}),
      );

      final body = _asMap(res.data);
      final rawUser = _extractUserPayload(body);
      if (rawUser != null) {
        final parsed = User.fromJson(rawUser);
        await AppStorage.setUser(parsed);
      }
      return _AuthMeStatus.ok;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return _AuthMeStatus.unauthorized;
      return _AuthMeStatus.otherError;
    } catch (_) {
      return _AuthMeStatus.otherError;
    }
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  Map<String, dynamic>? _extractUserPayload(Map<String, dynamic> body) {
    if (body['user'] is Map) {
      return Map<String, dynamic>.from(body['user'] as Map);
    }
    if (body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    if (body['id'] != null && body['email'] != null) {
      return body;
    }
    return null;
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  String _mask(String? value) {
    if (value == null || value.isEmpty) return '-';
    if (value.length <= 8) return '***';
    return '${value.substring(0, 4)}...${value.substring(value.length - 4)}';
  }
}

enum _AuthMeStatus { ok, unauthorized, otherError }
