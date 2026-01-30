import 'package:get/get.dart';
import 'game_detail_controller.dart';

class GameDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GameDetailController>(() => GameDetailController());
  }
}

