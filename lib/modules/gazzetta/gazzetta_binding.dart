import 'package:get/get.dart';

import 'gazzetta_controller.dart';

class GazzettaBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<GazzettaController>()) {
      Get.lazyPut<GazzettaController>(() => GazzettaController());
    }
  }
}
