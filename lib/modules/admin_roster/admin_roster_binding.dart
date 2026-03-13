import 'package:get/get.dart';
import 'admin_roster_controller.dart';

class AdminRosterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminRosterController>(() => AdminRosterController());
  }
}
