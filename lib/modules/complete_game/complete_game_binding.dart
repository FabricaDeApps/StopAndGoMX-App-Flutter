import 'package:get/get.dart';
import 'complete_game_controller.dart';

class CompleteGameBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CompleteGameController>(() => CompleteGameController());
  }
}

