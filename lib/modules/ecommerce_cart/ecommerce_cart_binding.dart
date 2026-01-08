import 'package:get/get.dart';
import 'ecommerce_cart_controller.dart';

class EcommerceCartBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EcommerceCartController>(() => EcommerceCartController());
  }
}

