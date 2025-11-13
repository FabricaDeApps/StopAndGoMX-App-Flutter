import 'package:get/get.dart';
import 'create_trainning_controller.dart';

class CreateTrainningBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreateTrainningController>(() => CreateTrainningController());
  }
}

