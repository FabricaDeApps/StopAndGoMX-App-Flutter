import 'package:get/get.dart';
import 'combine_events_controller.dart';

class CombineEventsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CombineEventsController>(() => CombineEventsController());
  }
}

