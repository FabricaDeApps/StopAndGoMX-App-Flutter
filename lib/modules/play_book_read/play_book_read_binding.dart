import 'package:get/get.dart';
import 'play_book_read_controller.dart';

class PlayBookReadBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PlayBookReadController>(() => PlayBookReadController());
  }
}

