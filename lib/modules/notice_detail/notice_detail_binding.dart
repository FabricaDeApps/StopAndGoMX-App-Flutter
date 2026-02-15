import 'package:get/get.dart';

import 'notice_detail_controller.dart';

class NoticeDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NoticeDetailController>(() => NoticeDetailController());
  }
}
