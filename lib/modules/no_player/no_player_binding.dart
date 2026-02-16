import 'package:get/get.dart';
import 'no_player_controller.dart';

class NoPlayerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NoPlayerController>(() => NoPlayerController());
  }
}
