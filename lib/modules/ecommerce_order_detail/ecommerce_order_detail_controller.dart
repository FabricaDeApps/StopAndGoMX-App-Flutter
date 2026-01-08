import 'package:get/get.dart';
import 'package:stopandgo/core/models/ecommerce/ecommerce_order_detail_model.dart';
import 'package:stopandgo/core/network/api_repository.dart';

class EcommerceOrderDetailController extends GetxController {
  final _api = Get.find<ApiRepository>();

  final isLoading = true.obs;
  final error = RxnString();
  final order = Rxn<EcommerceOrderDetailModel>();

  late final int orderId;

  @override
  void onInit() {
    super.onInit();
    final args = (Get.arguments as Map<String, dynamic>?) ?? {};
    orderId = (args['orderId'] as int?) ?? 0;
    load();
  }

  Future<void> load() async {
    try {
      isLoading.value = true;
      error.value = null;

      final o = await _api.ecommerceOrderShow(orderId);
      order.value = o;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
