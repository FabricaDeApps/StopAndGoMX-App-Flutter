import 'package:get/get.dart';
import 'ecommerce_home_controller.dart';

class EcommerceHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EcommerceHomeController>(() => EcommerceHomeController());
  }
}

