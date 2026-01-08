import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/services/ecommerce_cart_service.dart';
import 'package:stopandgo/routes/app_routes.dart';

import '../../../core/models/ecommerce/product_model.dart';
import '../../../core/network/api_repository.dart';

class EcommerceProductsController extends GetxController {
  final _api = Get.find<ApiRepository>();
  final cartService = Get.find<EcommerceCartService>();

  final isLoading = false.obs;
  final error = RxnString();
  final products = <ProductModel>[].obs;

  late final int categoryId;
  late final String categoryName;

  final searchCtrl = TextEditingController();
  Timer? _debounce;

  final quickAdding = <int, bool>{}.obs;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments as Map<String, dynamic>?;

    categoryId = (args?['categoryId'] as int?) ?? 0;
    categoryName = (args?['categoryName'] as String?) ?? 'Productos';

    load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) return;
      cartService.refreshCart();
    });
  }

  @override
  void onClose() {
    _debounce?.cancel();
    searchCtrl.dispose();
    super.onClose();
  }

  Future<void> load({String? q}) async {
    try {
      isLoading.value = true;
      error.value = null;

      final list = await _api.ecommerceProducts(categoryId: categoryId, q: q);
      products.assignAll(list);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      load(q: value.trim());
    });
  }

  void clearSearch() {
    searchCtrl.clear();
    load();
  }

  void openProduct(ProductModel p) {
    Get.toNamed(Routes.ecommerceProductDetail, arguments: {'productId': p.id});
  }

  void openCart() {
    Get.toNamed(Routes.ecommerceCart);
  }

  Future<void> quickAdd(ProductModel p) async {
    if (p.activeVariants.length != 1) return;

    final variantId = p.activeVariants.first.id;

    try {
      quickAdding[p.id] = true;
      await _api.ecommerceCartAddItem(variantId: variantId, qty: 1);
      Get.snackbar('Listo', 'Agregado al carrito');
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      cartService.refreshCart();
      quickAdding[p.id] = false;
    }
  }
}
