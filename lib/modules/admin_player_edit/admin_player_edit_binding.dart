import 'package:get/get.dart';
import 'admin_player_edit_controller.dart';

class AdminPlayerEditBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminPlayerEditController>(() => AdminPlayerEditController());
  }
}
