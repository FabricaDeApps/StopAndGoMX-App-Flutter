import 'package:get/get.dart';
import 'play_book_controller.dart';

class PlayBookBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PlayBookController>(() => PlayBookController());
  }
}

