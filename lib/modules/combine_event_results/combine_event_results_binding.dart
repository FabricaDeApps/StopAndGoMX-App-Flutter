import 'package:get/get.dart';
import 'combine_event_results_controller.dart';

class CombineEventResultsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CombineEventResultsController>(() => CombineEventResultsController());
  }
}

