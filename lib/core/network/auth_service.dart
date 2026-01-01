// lib/core/auth/auth_service.dart
import 'package:get/get.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import '../network/token_storage.dart';
import '../../routes/app_routes.dart';

class AuthService {
  static Future<void> forceLogout() async {
    final storage = Get.find<TokenStorage>();
    storage.clear();
    AppStorage.clearAll();
    Get.offAllNamed(Routes.login);
  }
}
