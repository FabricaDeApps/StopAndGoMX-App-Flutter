import 'package:get/get.dart';
import 'change_role_controller.dart';

class ChangeRoleBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChangeRoleController>(() => ChangeRoleController());
  }
}

