import 'package:get/get.dart';
import 'package:stopandgo/core/models/ecommerce/ecommerce_order_detail_model.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/routes/app_routes.dart';

class EcommerceOrderResultController extends GetxController {
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

  // Acciones UI
  void goHomeShop() {
    Get.offAllNamed(Routes.ecommerceHome);
  }

  void goOrders() {
    Get.offNamed(Routes.ecommerceOrders);
  }

  void goOrderDetail() {
    Get.offNamed(Routes.home);
  }

  void retryPayment() {
    Get.snackbar('Pago', 'Reintentar pago (pendiente de implementar)');
    Get.offAllNamed(Routes.ecommerceCheckout);
  }
}
