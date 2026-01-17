import 'package:get/get.dart';
import 'init_live_controller.dart';

class InitLiveBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InitLiveController>(() => InitLiveController());
  }
}

