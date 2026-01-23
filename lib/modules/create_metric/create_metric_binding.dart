import 'package:get/get.dart';
import 'create_metric_controller.dart';

class CreateMetricBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreateMetricController>(() => CreateMetricController());
  }
}

