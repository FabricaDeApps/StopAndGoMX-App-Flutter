import 'package:get/get.dart';
import 'ecommerce_checkout_controller.dart';

class EcommerceCheckoutBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EcommerceCheckoutController>(() => EcommerceCheckoutController());
  }
}

