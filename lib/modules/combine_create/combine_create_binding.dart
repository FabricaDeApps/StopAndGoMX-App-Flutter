import 'package:get/get.dart';
import 'combine_create_controller.dart';

class CombineCreateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CombineCreateController>(() => CombineCreateController());
  }
}

