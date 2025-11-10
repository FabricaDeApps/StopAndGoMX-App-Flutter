import 'package:get/get.dart';
import 'new_game_controller.dart';

class NewGameBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NewGameController>(() => NewGameController());
  }
}

