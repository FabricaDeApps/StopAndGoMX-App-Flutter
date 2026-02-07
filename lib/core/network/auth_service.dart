// lib/core/auth/auth_service.dart
import 'package:get/get.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import '../network/token_storage.dart';
import '../../routes/app_routes.dart';

class AuthService {
  static bool _logoutInProgress = false;

  static Future<void> forceLogout() async {
    if (_logoutInProgress) return;
    _logoutInProgress = true;

    try {
      if (Get.isRegistered<TokenStorage>()) {
        final storage = Get.find<TokenStorage>();
        storage.clear();
      }
      await AppStorage.clearAll();

      // Evita recrear el login mientras ya está en pantalla.
      if (Get.currentRoute != Routes.login) {
        Get.offAllNamed(Routes.login);
      }
    } finally {
      _logoutInProgress = false;
    }
  }
}
