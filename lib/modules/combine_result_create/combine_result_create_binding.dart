import 'package:get/get.dart';
import 'combine_result_create_controller.dart';

class CombineResultCreateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CombineResultCreateController>(() => CombineResultCreateController());
  }
}

