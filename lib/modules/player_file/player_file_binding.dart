import 'package:get/get.dart';

import 'player_file_controller.dart';

class PlayerFileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PlayerFileController>(() => PlayerFileController());
  }
}
