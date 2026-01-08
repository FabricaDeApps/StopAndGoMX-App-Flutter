import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:stopandgo/routes/app_routes.dart';
import '../../../core/network/api_repository.dart';
import '../../../core/services/ecommerce_cart_service.dart';
import '../../../core/models/ecommerce/product_detail_model.dart';

class EcommerceProductDetailController extends GetxController {
  final _api = Get.find<ApiRepository>();
  final cartService = Get.find<EcommerceCartService>();

  final isLoading = false.obs;
  final isAdding = false.obs;
  final error = RxnString();

  final product = Rxn<ProductDetailModel>();

  late final int productId;

  final selectedVariantId = RxnInt();
  final qty = 1.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;

    productId = (args?['productId'] as int?) ?? 0;
    load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) return;
      cartService.refreshCart();
    });
  }

  void openCart() {
    Get.toNamed(Routes.ecommerceCart);
  }

  Future<void> load() async {
    try {
      isLoading.value = true;
      error.value = null;

      final p = await _api.ecommerceProductDetail(productId: productId);
      product.value = p;

      if (p.variants.length == 1) {
        selectedVariantId.value = p.variants.first.id;
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void selectVariant(int variantId) {
    selectedVariantId.value = variantId;
  }

  void incQty() => qty.value++;
  void decQty() {
    if (qty.value > 1) qty.value--;
  }

  Future<void> addToCart() async {
    final p = product.value;
    if (p == null) return;

    final vId = selectedVariantId.value;
    if (vId == null) {
      Get.snackbar('Falta seleccionar', 'Selecciona una variante.');
      return;
    }

    try {
      isAdding.value = true;

      await _api.ecommerceCartAddItem(variantId: vId, qty: qty.value);

      cartService.addOptimistic(qty.value);
      Get.snackbar('Listo', 'Agregado al carrito');
    } catch (e) {
      Get.snackbar('Error', e.toString());
      await cartService.refreshCart();
    } finally {
      cartService.refreshCart();
      isAdding.value = false;
    }
  }
}
