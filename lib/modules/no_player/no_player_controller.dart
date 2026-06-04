import 'package:get/get.dart';
import 'package:stopandgo/routes/app_routes.dart';
import '../../../core/network/api_repository.dart';

class NoPlayerController extends GetxController {
  final _api = Get.find<ApiRepository>();

  Future<void> logout() async {
    try {
      await _api.logout(reason: 'logout');
    } catch (_) {
      Get.offAllNamed(Routes.login);
    } finally {
      Get.offAllNamed(Routes.login);
    }
  }
}
