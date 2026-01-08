import 'package:get/get.dart';
import 'ecommerce_order_detail_controller.dart';

class EcommerceOrderDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EcommerceOrderDetailController>(() => EcommerceOrderDetailController());
  }
}

