import 'package:get/get.dart';
import 'trainnings_controller.dart';

class TrainningsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TrainingsController>(() => TrainingsController());
  }
}
