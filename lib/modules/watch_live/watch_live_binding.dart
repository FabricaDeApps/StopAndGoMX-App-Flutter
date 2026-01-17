import 'package:get/get.dart';
import 'watch_live_controller.dart';

class WatchLiveBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WatchLiveController>(() => WatchLiveController());
  }
}

