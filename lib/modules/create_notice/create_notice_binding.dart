import 'package:get/get.dart';

import 'create_notice_controller.dart';

class CreateNoticeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreateNoticeController>(() => CreateNoticeController());
  }
}
