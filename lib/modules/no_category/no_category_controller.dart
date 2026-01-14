import 'package:get/get.dart';
import 'package:stopandgo/core/network/token_storage.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/routes/app_routes.dart';
import '../../../core/network/api_repository.dart';

class NoCategoryController extends GetxController {
  final _api = Get.find<ApiRepository>();

  final isLoading = false.obs;
  final error = RxnString();

  Future<void> logout() async {
    try {
      final tokenStorage = Get.find<TokenStorage>();
      tokenStorage.clear();
      AppStorage.clearAll();
      await _api.logout();
    } catch (_) {
      Get.offAllNamed(Routes.login);
    } finally {
      Get.offAllNamed(Routes.login);
    }
  }
}
