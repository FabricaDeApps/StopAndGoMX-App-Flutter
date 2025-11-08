import 'package:get/get.dart';
import '../core/network/api_repository.dart';
import '../core/network/token_storage.dart';

/// AppBinding: se ejecuta al inicio de la app y registra los servicios globales.
///
/// De esta forma no necesitas inicializarlos manualmente en cada controlador.
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
  }
}
