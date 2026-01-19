import 'package:get/get.dart';
import 'player_trainings_controller.dart';

class PlayerTrainingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PlayerTrainingsController>(() => PlayerTrainingsController());
  }
}

