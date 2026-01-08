import 'package:get/get.dart';
import 'ecommerce_products_controller.dart';

class EcommerceProductsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EcommerceProductsController>(() => EcommerceProductsController());
  }
}

