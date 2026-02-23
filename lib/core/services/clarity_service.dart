import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:stopandgo/core/config/flavor_config.dart';
import 'package:stopandgo/core/storage/app_storage.dart';

class ClarityService {
  static const String _projectId = 'vlmufxjyz2';
  static const bool _forceInDebug = bool.fromEnvironment(
    'CLARITY_FORCE_DEBUG',
    defaultValue: false,
  );
  static bool _enabled = false;

  static bool get isEnabled => _enabled;

  static Widget wrapApp(Widget app) {
    if (!_shouldEnable) return app;

    _enabled = true;
    return ClarityWidget(
      app: app,
      clarityConfig: ClarityConfig(
        projectId: _projectId,
        logLevel: LogLevel.Info,
      ),
    );
  }

  static void bootstrapContextFromStorage() {
    if (!isEnabled) return;

    _setTag('flavor', FlavorConfig.I.flavor.name);

    final orgId =
        FlavorConfig.I.organizationId ?? AppStorage.getOrganization()?.id;
    if (orgId != null) {
      _setTag('organization_id', orgId.toString());
    }

    final role = AppStorage.getActiveRole();
    if (role != null && role.trim().isNotEmpty) {
      _setTag('role', role.trim().toLowerCase());
    }

    final user = AppStorage.getUser();
    if (user != null && user.id > 0) {
      Clarity.setCustomUserId(user.id.toString());
    }
  }

  static void setUserContext({
    required int userId,
    required String role,
    int? organizationId,
  }) {
    if (!isEnabled) return;

    if (userId > 0) {
      Clarity.setCustomUserId(userId.toString());
    }

    final normalizedRole = role.trim().toLowerCase();
    if (normalizedRole.isNotEmpty) {
      _setTag('role', normalizedRole);
    }

    final orgId = organizationId ?? FlavorConfig.I.organizationId;
    if (orgId != null) {
      _setTag('organization_id', orgId.toString());
    }

    _setTag('flavor', FlavorConfig.I.flavor.name);
  }

  static void clearUserContext() {
    if (!isEnabled) return;

    _setTag('role', 'guest');
    _setTag('selected_category_id', 'none');
    _setTag('selected_player_id', 'none');
  }

  static void setSelectedCategory(int? categoryId) {
    if (!isEnabled || categoryId == null) return;
    _setTag('selected_category_id', categoryId.toString());
  }

  static void setSelectedPlayer(int? playerId) {
    if (!isEnabled || playerId == null) return;
    _setTag('selected_player_id', playerId.toString());
  }

  static void trackScreen(String? screenName) {
    if (!isEnabled) return;

    final name = (screenName ?? '').trim();
    if (name.isEmpty) return;
    Clarity.setCurrentScreenName(name);
  }

  static void trackEvent(String value) {
    if (!isEnabled) return;

    final event = value.trim();
    if (event.isEmpty) return;
    Clarity.sendCustomEvent(event);
  }

  static bool get _shouldEnable {
    return (kReleaseMode || _forceInDebug) && _projectId.trim().isNotEmpty;
  }

  static void _setTag(String key, String value) {
    final k = key.trim();
    final v = value.trim();
    if (k.isEmpty || v.isEmpty) return;
    Clarity.setCustomTag(k, v);
  }
}
