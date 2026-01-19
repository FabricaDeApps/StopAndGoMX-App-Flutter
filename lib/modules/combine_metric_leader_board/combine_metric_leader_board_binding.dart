import 'package:get/get.dart';
import 'combine_metric_leader_board_controller.dart';

class CombineMetricLeaderBoardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CombineMetricLeaderBoardController>(() => CombineMetricLeaderBoardController());
  }
}

