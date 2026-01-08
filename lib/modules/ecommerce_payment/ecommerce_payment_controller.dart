import 'package:get/get.dart';
import '../../../core/network/api_repository.dart';

class EcommercePaymentController extends GetxController {
  final _api = Get.find<ApiRepository>();

  final isLoading = false.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    // TODO: init logic
  }

  Future<void> load() async {
    try {
      isLoading.value = true;
      error.value = null;
      // TODO: consume repo
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}

