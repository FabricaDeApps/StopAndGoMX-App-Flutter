import 'package:get/get.dart';
import 'team_selector_controller.dart';

class TeamSelectorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TeamSelectorController>(() => TeamSelectorController());
  }
}
