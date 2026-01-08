import 'package:get/get.dart';
import 'ecommerce_product_detail_controller.dart';

class EcommerceProductDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EcommerceProductDetailController>(() => EcommerceProductDetailController());
  }
}

