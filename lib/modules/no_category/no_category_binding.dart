import 'package:get/get.dart';
import 'no_category_controller.dart';

class NoCategoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NoCategoryController>(() => NoCategoryController());
  }
}

