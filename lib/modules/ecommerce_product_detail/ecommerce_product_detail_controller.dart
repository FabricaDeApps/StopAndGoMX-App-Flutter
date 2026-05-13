import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:stopandgo/routes/app_routes.dart';
import '../../../core/network/api_repository.dart';
import '../../../core/services/ecommerce_cart_service.dart';
import '../../../core/models/ecommerce/product_detail_model.dart';
import '../../../core/models/ecommerce/product_variant_model.dart';

class EcommerceProductDetailController extends GetxController {
  final _api = Get.find<ApiRepository>();
  final cartService = Get.find<EcommerceCartService>();

  final isLoading = false.obs;
  final isAdding = false.obs;
  final isResolving = false.obs;
  final error = RxnString();

  final product = Rxn<ProductDetailModel>();

  late final int productId;

  final selectedVariantId = RxnInt();
  final resolvedVariant = Rxn<ProductVariantListModel>();
  final selectedValueIdsByGroup = <int, int>{}.obs;
  final qty = 1.obs;

  bool get usesAttributeSelection =>
      (product.value?.attributeGroups.isNotEmpty ?? false) &&
      (product.value?.variantMatrix.isNotEmpty ?? false);

  ProductVariantListModel? get selectedVariant {
    final p = product.value;
    if (p == null) return null;

    if (usesAttributeSelection) {
      return resolvedVariant.value;
    }

    final vId = selectedVariantId.value;
    if (vId == null) return null;

    for (final variant in p.variants) {
      if (variant.id == vId) return variant;
    }
    return null;
  }

  bool get isSelectionComplete {
    final p = product.value;
    if (p == null) return false;
    if (!usesAttributeSelection) return selectedVariantId.value != null;
    return selectedValueIdsByGroup.length == p.attributeGroups.length;
  }

  bool get canAddToCart {
    final variant = selectedVariant;
    if (variant == null) return false;
    if (!variant.isActive) return false;
    return variant.stock > 0;
  }

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
      selectedVariantId.value = null;
      resolvedVariant.value = null;
      selectedValueIdsByGroup.clear();

      if (usesAttributeSelection) {
        for (final group in p.attributeGroups) {
          if (group.values.length == 1) {
            selectedValueIdsByGroup[group.id] = group.values.first.id;
          }
        }
        await _resolveVariantIfReady();
      } else if (p.variants.length == 1) {
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

  Future<void> selectAttributeValue({
    required int groupId,
    required int valueId,
  }) async {
    selectedValueIdsByGroup[groupId] = valueId;
    resolvedVariant.value = null;
    await _resolveVariantIfReady();
  }

  Future<void> _resolveVariantIfReady() async {
    final p = product.value;
    if (p == null || !usesAttributeSelection) return;

    if (selectedValueIdsByGroup.length != p.attributeGroups.length) {
      return;
    }

    final valueIds = p.attributeGroups
        .map((group) => selectedValueIdsByGroup[group.id])
        .whereType<int>()
        .toList();

    if (valueIds.length != p.attributeGroups.length) return;

    try {
      isResolving.value = true;
      error.value = null;
      final variant = await _api.ecommerceResolveVariant(
        productId: p.id,
        valueIds: valueIds,
      );
      selectedVariantId.value = variant.id;
      resolvedVariant.value = variant;
    } catch (e) {
      selectedVariantId.value = null;
      resolvedVariant.value = null;
      Get.snackbar(
        'Combinación no disponible',
        'Esa combinación no tiene una variante activa.',
      );
    } finally {
      isResolving.value = false;
    }
  }

  void incQty() => qty.value++;
  void decQty() {
    if (qty.value > 1) qty.value--;
  }

  Future<void> addToCart() async {
    final p = product.value;
    if (p == null) return;

    final vId = selectedVariantId.value;
    if (!isSelectionComplete) {
      final message = usesAttributeSelection
          ? 'Selecciona todos los atributos.'
          : 'Selecciona una variante.';
      Get.snackbar('Falta seleccionar', message);
      return;
    }

    if (isResolving.value) {
      Get.snackbar('Espera un momento', 'Estamos validando tu selección.');
      return;
    }

    if (vId == null || !canAddToCart) {
      final message = selectedVariant == null
          ? 'No se pudo resolver la variante seleccionada.'
          : 'La variante seleccionada no tiene stock disponible.';
      Get.snackbar('No disponible', message);
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
