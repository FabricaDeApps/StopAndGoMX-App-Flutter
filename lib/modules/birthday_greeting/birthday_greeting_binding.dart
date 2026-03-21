import 'package:get/get.dart';
import 'birthday_greeting_controller.dart';

class BirthdayGreetingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BirthdayGreetingController>(() => BirthdayGreetingController());
  }
}
