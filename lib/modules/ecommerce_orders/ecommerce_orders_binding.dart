import 'package:get/get.dart';
import 'ecommerce_orders_controller.dart';

class EcommerceOrdersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EcommerceOrdersController>(() => EcommerceOrdersController());
  }
}

