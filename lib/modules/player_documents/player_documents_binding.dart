import 'package:get/get.dart';
import 'player_documents_controller.dart';

class PlayerDocumentsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PlayerDocumentsController>(() => PlayerDocumentsController());
  }
}

