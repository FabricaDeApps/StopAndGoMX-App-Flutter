import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:stopandgo/core/constants/api_endpoints.dart';
import 'package:stopandgo/core/network/api_client.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/core/utils/device_info.dart';
import 'package:uuid/uuid.dart';

class AppUsageSessionService extends GetxService with WidgetsBindingObserver {
  static const Duration _heartbeatInterval = Duration(seconds: 45);

  final Dio _dio = ApiClient.dio;
  final Uuid _uuid = const Uuid();

  Timer? _heartbeatTimer;
  Map<String, dynamic>? _activeSession;
  String _currentScreen = 'unknown';
  bool _isStarting = false;
  bool _isEnding = false;
  bool _isHeartbeatInFlight = false;

  late final String _platform;
  String _appVersion = 'unknown';
  String _buildNumber = 'unknown';
  String _deviceId = 'unknown';
  String _deviceName = 'unknown';

  Future<AppUsageSessionService> init() async {
    WidgetsBinding.instance.addObserver(this);

    _platform = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
    _activeSession = AppStorage.getAppUsageSession();
    _currentScreen = _normalizeScreen(Get.currentRoute);

    await _loadStaticContext();
    return this;
  }

  Future<void> handleAuthenticatedEntry({String source = 'app_open'}) async {
    if (!_isAuthenticated || !_isAppInForeground) return;

    if (_hasPersistedSession) {
      await _resumePersistedSession();
      return;
    }

    await _startSession(source: source);
  }

  Future<void> endSession({String reason = 'background'}) async {
    if (_isEnding) return;

    final session = _activeSession;
    if (session == null) {
      await clearSessionState();
      return;
    }

    _isEnding = true;
    _stopHeartbeat();

    try {
      final endedAt = _formatTimestamp(DateTime.now());
      await _dio.post(
        ApiEndpoints.appUsageSessionsEnd,
        data: {
          'session_key': session['session_key'],
          'ended_at': endedAt,
          'meta': {'reason': reason},
        },
        options: Options(headers: const {'Accept': 'application/json'}),
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code != 401) {
        debugPrint('app usage end failed [$code]: ${e.message}');
      }
    } catch (e) {
      debugPrint('app usage end failed: $e');
    } finally {
      await clearSessionState();
      _isEnding = false;
    }
  }

  Future<void> clearSessionState() async {
    _stopHeartbeat();
    _activeSession = null;
    await AppStorage.clearAppUsageSession();
  }

  void updateCurrentScreen(String? route) {
    final next = _normalizeScreen(route);
    if (next.isNotEmpty) {
      _currentScreen = next;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(handleAuthenticatedEntry(source: 'app_open'));
        break;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(endSession(reason: 'background'));
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }

  Future<void> _loadStaticContext() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = info.version;
      _buildNumber = info.buildNumber;
    } catch (e) {
      debugPrint('app usage package info unavailable: $e');
    }

    try {
      final deviceInfo = await DeviceInfoHelper.getAppUsageDeviceInfo();
      _deviceId = (deviceInfo['device_id'] ?? '').trim().isEmpty
          ? 'unknown'
          : deviceInfo['device_id']!.trim();
      _deviceName = (deviceInfo['device_name'] ?? '').trim().isEmpty
          ? 'unknown'
          : deviceInfo['device_name']!.trim();
    } catch (e) {
      debugPrint('app usage device info unavailable: $e');
    }
  }

  bool get _isAuthenticated => AppStorage.getUser() != null;

  bool get _isAppInForeground {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    return lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }

  bool get _hasPersistedSession =>
      _activeSession != null &&
      ((_activeSession!['session_key']?.toString() ?? '').trim().isNotEmpty);

  Future<void> _resumePersistedSession() async {
    final ok = await _sendHeartbeat();
    if (ok) {
      _ensureHeartbeat();
      return;
    }

    await clearSessionState();
    await _startSession(source: 'app_open');
  }

  Future<void> _startSession({required String source}) async {
    if (_isStarting || !_isAuthenticated || !_isAppInForeground) return;
    if (_hasPersistedSession) {
      _ensureHeartbeat();
      return;
    }

    _isStarting = true;
    try {
      final now = DateTime.now();
      final sessionKey = _uuid.v4();
      final startedAt = _formatTimestamp(now);
      final payload = <String, dynamic>{
        'session_key': sessionKey,
        'platform': _platform,
        'app_version': _appVersion,
        'build_number': _buildNumber,
        'device_id': _deviceId,
        'device_name': _deviceName,
        'started_at': startedAt,
        'meta': {'screen': _currentScreen, 'source': source},
      };

      final res = await _dio.post(
        ApiEndpoints.appUsageSessionsStart,
        data: payload,
        options: Options(headers: const {'Accept': 'application/json'}),
      );

      final body = _asMap(res.data);
      _activeSession = {
        'session_key': body['session_key']?.toString() ?? sessionKey,
        'session_id': body['session_id'],
        'started_at': body['started_at']?.toString() ?? startedAt,
        'platform': _platform,
        'app_version': _appVersion,
        'build_number': _buildNumber,
        'device_id': _deviceId,
        'device_name': _deviceName,
      };
      await AppStorage.setAppUsageSession(_activeSession);
      _ensureHeartbeat();
    } on DioException catch (e) {
      debugPrint(
        'app usage start failed [${e.response?.statusCode}]: ${e.message}',
      );
    } catch (e) {
      debugPrint('app usage start failed: $e');
    } finally {
      _isStarting = false;
    }
  }

  Future<bool> _sendHeartbeat() async {
    final session = _activeSession;
    if (session == null || _isHeartbeatInFlight || !_isAuthenticated) {
      return false;
    }

    _isHeartbeatInFlight = true;
    try {
      await _dio.post(
        ApiEndpoints.appUsageSessionsHeartbeat,
        data: {
          'session_key': session['session_key'],
          'last_seen_at': _formatTimestamp(DateTime.now()),
          'meta': {'screen': _currentScreen},
        },
        options: Options(headers: const {'Accept': 'application/json'}),
      );
      return true;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 403 || code == 422) {
        return false;
      }
      debugPrint('app usage heartbeat failed [$code]: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('app usage heartbeat failed: $e');
      return false;
    } finally {
      _isHeartbeatInFlight = false;
    }
  }

  void _ensureHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      if (!_isAuthenticated || !_isAppInForeground) return;
      unawaited(_sendHeartbeat());
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  String _normalizeScreen(String? route) {
    final clean = (route ?? '').trim();
    if (clean.isEmpty || clean == '/') return 'splash';
    return clean.replaceAll(RegExp(r'^/+'), '');
  }

  String _formatTimestamp(DateTime value) {
    final local = value.toLocal();
    final base = local.toIso8601String().split('.').first;
    final offset = local.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return '$base$sign$hours:$minutes';
  }
}
