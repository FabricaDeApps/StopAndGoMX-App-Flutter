import 'package:get/get.dart';

import 'recompensas_coach_controller.dart';

class RecompensasCoachBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RecompensasCoachController>(() => RecompensasCoachController());
  }
}
