import 'package:get/get.dart';
import 'attendece_game_controller.dart';

class AttendeceGameBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AttendanceGameController>(() => AttendanceGameController());
  }
}
