import 'package:get/get.dart';
import 'broadcast_live_controller.dart';

class BroadcastLiveBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BroadcastLiveController>(() => BroadcastLiveController());
  }
}

