import 'package:get/get.dart';
import 'assign_player_controller.dart';

class AssignPlayerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AssignPlayerController>(() => AssignPlayerController());
  }
}

