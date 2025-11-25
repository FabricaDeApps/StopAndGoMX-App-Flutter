import 'package:get/get.dart';
import 'roster_controller.dart';

class RosterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RosterController>(() => RosterController());
  }
}

