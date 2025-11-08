import 'package:get/get.dart';

class ImageController extends GetxController {
  late final String url;

  @override
  void onInit() {
    super.onInit();
    url = (Get.arguments?['url'] as String?) ?? '';
  }

  bool get hasUrl => url.isNotEmpty;
}
