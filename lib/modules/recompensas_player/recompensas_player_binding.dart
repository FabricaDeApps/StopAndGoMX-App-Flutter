import 'package:get/get.dart';

import 'recompensas_player_controller.dart';

class RecompensasPlayerBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<RecompensasPlayerController>()) {
      Get.lazyPut<RecompensasPlayerController>(
        () => RecompensasPlayerController(),
      );
    }
  }
}
