import 'package:get/get.dart';
import 'package:stopandgo/modules/play_book_create/play_book_create_controller.dart';

class PlayBookCreateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PlayBookCreateController>(() => PlayBookCreateController());
  }
}
