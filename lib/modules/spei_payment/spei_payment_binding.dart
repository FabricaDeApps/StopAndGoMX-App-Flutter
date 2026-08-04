import 'package:get/get.dart';

import 'spei_payment_controller.dart';

class SpeiPaymentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SpeiPaymentController>(() => SpeiPaymentController());
  }
}
