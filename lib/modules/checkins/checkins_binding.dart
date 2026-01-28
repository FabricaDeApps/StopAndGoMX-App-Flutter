import 'package:get/get.dart';
import 'checkins_controller.dart';

class CheckinsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CheckinsController>(() => CheckinsController());
  }
}

