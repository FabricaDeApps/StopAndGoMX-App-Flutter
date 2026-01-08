import 'package:get/get.dart';
import 'ecommerce_payment_controller.dart';

class EcommercePaymentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EcommercePaymentController>(() => EcommercePaymentController());
  }
}

