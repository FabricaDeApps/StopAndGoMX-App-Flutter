import 'package:get/get.dart';
import 'ecommerce_order_result_controller.dart';

class EcommerceOrderResultBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EcommerceOrderResultController>(() => EcommerceOrderResultController());
  }
}

