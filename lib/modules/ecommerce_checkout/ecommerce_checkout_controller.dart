import 'package:get/get.dart';
import 'package:stopandgo/core/models/ecommerce/cart_model.dart';
import 'package:stopandgo/core/models/ecommerce/checkout_result_model.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/services/ecommerce_cart_service.dart';
import 'package:stopandgo/routes/app_routes.dart';

class EcommerceCheckoutController extends GetxController {
  final _api = Get.find<ApiRepository>();
  final cartService = Get.find<EcommerceCartService>();

  final isLoading = false.obs;
  final error = RxnString();

  final cart = Rxn<CartModel>();

  final isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    try {
      isLoading.value = true;
      error.value = null;

      final c = await _api.ecommerceCart();
      cart.value = c;

      await cartService.refreshCart();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  bool get canSubmit {
    final count = cartService.cartCount.value;
    return !isSubmitting.value && count > 0;
  }

  Future<void> submitCheckout() async {
    if (!canSubmit) return;

    try {
      isSubmitting.value = true;
      error.value = null;

      final result = await _api.ecommerceCheckout(fulfillmentType: 'pickup');

      final intentUrl = result.intentCreateUrl;
      if (intentUrl == null || intentUrl.isEmpty) {
        Get.snackbar('Checkout', 'No se recibió URL para crear el intent.');
        return;
      }

      final intentRes = await _api.createPaymentIntentByUrl(intentUrl);

      final url =
          (intentRes['init_url'] ??
                  intentRes['init_point'] ??
                  intentRes['sandbox_init_point'] ??
                  intentRes['checkout_url'])
              ?.toString();

      if (url == null || url.isEmpty) {
        Get.snackbar('Pago', 'No llegó la URL de pago.');
        return;
      }

      Get.toNamed(
        Routes.ecommercePayment,
        arguments: {'url': url, 'orderId': result.orderId},
      );
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Checkout', 'No se pudo finalizar: $e');
    } finally {
      isSubmitting.value = false;
    }
  }
}
