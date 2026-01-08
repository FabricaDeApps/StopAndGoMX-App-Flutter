import 'package:get/get.dart';
import '../models/ecommerce/cart_model.dart';
import '../network/api_repository.dart';

class EcommerceCartService extends GetxService {
  final ApiRepository _api = Get.find<ApiRepository>();

  final isLoading = false.obs;
  final cartCount = 0.obs;

  final cart = Rxn<CartModel>();
  final subtotal = 0.0.obs;

  Future<void> refreshCart() async {
    try {
      isLoading.value = true;

      final c = await _api.ecommerceCart();
      cart.value = c;

      cartCount.value = c.items.fold<int>(0, (sum, it) => sum + it.qty);
      subtotal.value = c.subtotal;
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  void addOptimistic(int qty) {
    cartCount.value = cartCount.value + qty;
  }

  void setCount(int value) {
    cartCount.value = value < 0 ? 0 : value;
  }
}
