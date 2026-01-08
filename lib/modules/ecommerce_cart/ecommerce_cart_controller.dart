import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/services/ecommerce_cart_service.dart';
import 'package:stopandgo/routes/app_routes.dart';
import '../../core/models/ecommerce/cart_model.dart';
import '../../core/models/ecommerce/cart_item_model.dart';

class EcommerceCartController extends GetxController {
  final _api = Get.find<ApiRepository>();
  final cartService = Get.find<EcommerceCartService>();

  final isLoading = false.obs;
  final error = RxnString();

  final cart = Rxn<CartModel>();

  final updatingItemIds = <int>{}.obs;
  final isClearing = false.obs;
  final isCheckingOut = false.obs;

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

  CartItemModel? getItem(int itemId) {
    final c = cart.value;
    if (c == null) return null;
    for (final it in c.items) {
      if (it.id == itemId) return it;
    }
    return null;
  }

  Future<void> setQty(CartItemModel item, int qty) async {
    if (qty < 1) {
      await removeItem(item);
      return;
    }

    if (updatingItemIds.contains(item.id)) return;

    try {
      updatingItemIds.add(item.id);

      await _api.ecommerceCartUpdateItem(cartItemId: item.id, qty: qty);

      final c = await _api.ecommerceCart();
      cart.value = c;

      await cartService.refreshCart();
    } catch (e) {
      Get.snackbar('Carrito', 'No se pudo actualizar: $e');
    } finally {
      updatingItemIds.remove(item.id);
    }
  }

  Future<void> inc(CartItemModel item) => setQty(item, item.qty + 1);

  Future<void> dec(CartItemModel item) => setQty(item, item.qty - 1);

  Future<void> removeItem(CartItemModel item) async {
    if (updatingItemIds.contains(item.id)) return;

    try {
      updatingItemIds.add(item.id);

      await _api.ecommerceCartRemoveItem(cartItemId: item.id);

      final c = await _api.ecommerceCart();
      cart.value = c;

      await cartService.refreshCart();
    } catch (e) {
      Get.snackbar('Carrito', 'No se pudo eliminar: $e');
    } finally {
      updatingItemIds.remove(item.id);
    }
  }

  Future<void> clearCart() async {
    if (isClearing.value) return;

    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Vaciar carrito'),
        content: const Text(
          '¿Seguro que quieres eliminar todos los artículos?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      isClearing.value = true;

      await _api.ecommerceCartClear();

      final c = await _api.ecommerceCart();
      cart.value = c;

      await cartService.refreshCart();
    } catch (e) {
      Get.snackbar('Carrito', 'No se pudo vaciar: $e');
    } finally {
      isClearing.value = false;
    }
  }

  void checkout() {
    if (cartService.cartCount.value <= 0) return;
    Get.toNamed(Routes.ecommerceCheckout);
  }
}
