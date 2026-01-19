import 'package:get/get.dart';
import 'combine_event_detail_controller.dart';

class CombineEventDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CombineEventDetailController>(() => CombineEventDetailController());
  }
}

