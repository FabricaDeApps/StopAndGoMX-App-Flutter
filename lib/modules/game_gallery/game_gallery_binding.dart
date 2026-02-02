import 'package:get/get.dart';
import 'game_gallery_controller.dart';

class GameGalleryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GameGalleryController>(() => GameGalleryController());
  }
}

