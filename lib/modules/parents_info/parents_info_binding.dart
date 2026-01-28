import 'package:get/get.dart';
import 'parents_info_controller.dart';

class ParentsInfoBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ParentsInfoController>(() => ParentsInfoController());
  }
}

