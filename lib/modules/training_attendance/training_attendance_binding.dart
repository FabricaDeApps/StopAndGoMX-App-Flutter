import 'package:get/get.dart';
import 'training_attendance_controller.dart';

class TrainingAttendanceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TrainingAttendanceController>(() => TrainingAttendanceController());
  }
}

