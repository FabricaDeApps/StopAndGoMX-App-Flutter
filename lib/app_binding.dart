import 'package:get/get.dart';
import 'package:stopandgo/core/services/ecommerce_cart_service.dart';
import '../core/network/api_repository.dart';
import '../core/network/token_storage.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // Registra almacenamiento de token
    if (!Get.isRegistered<TokenStorage>()) {
      Get.put(TokenStorage());
    }

    // Registra el repositorio principal para toda la app
    if (!Get.isRegistered<ApiRepository>()) {
      Get.put(ApiRepository(), permanent: true);
    }

    if (!Get.isRegistered<EcommerceCartService>()) {
      Get.put<EcommerceCartService>(EcommerceCartService(), permanent: true);
    }
  }
}
