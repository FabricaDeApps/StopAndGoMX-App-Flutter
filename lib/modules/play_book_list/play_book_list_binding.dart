import 'package:get/get.dart';
import 'play_book_list_controller.dart';

class PlayBookListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PlayBookListController>(() => PlayBookListController());
  }
}

