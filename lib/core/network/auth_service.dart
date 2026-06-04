// lib/core/auth/auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/config/flavor_config.dart';
import 'package:stopandgo/core/network/auth_repository.dart';
import 'package:stopandgo/core/services/app_usage_session_service.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import '../network/token_storage.dart';
import '../../routes/app_routes.dart';

class AuthService {
  static bool _logoutInProgress = false;

  static Future<void> forceLogout({String reason = 'unknown'}) async {
    if (_logoutInProgress) return;
    _logoutInProgress = true;

    try {
      if (Get.isRegistered<AppUsageSessionService>()) {
        await Get.find<AppUsageSessionService>().clearSessionState();
      }
      if (Get.isRegistered<AuthRepository>()) {
        await Get.find<AuthRepository>().logoutLocal();
      } else {
        if (Get.isRegistered<TokenStorage>()) {
          final storage = Get.find<TokenStorage>();
          await storage.clear();
        }
        await AppStorage.clearAll();
      }
      final next = FlavorConfig.I.isCustom ? Routes.login : Routes.teamSelector;
      debugPrint('navigating to auth entry कारण $reason');

      if (Get.currentRoute != next) {
        Get.offAllNamed(next);
      }
    } finally {
      _logoutInProgress = false;
    }
  }
}
