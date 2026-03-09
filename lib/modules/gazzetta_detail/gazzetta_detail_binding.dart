import 'package:get/get.dart';

import 'gazzetta_detail_controller.dart';

class GazzettaDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GazzettaDetailController>(() => GazzettaDetailController());
  }
}
