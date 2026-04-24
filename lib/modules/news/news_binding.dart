import 'package:get/get.dart';

import 'news_controller.dart';

class NewsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<NewsController>()) {
      Get.lazyPut<NewsController>(() => NewsController());
    }
  }
}
