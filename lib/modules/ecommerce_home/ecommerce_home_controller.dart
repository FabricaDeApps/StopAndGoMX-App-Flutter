import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/responses/organization_response.dart';
import 'package:stopandgo/core/services/ecommerce_cart_service.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/routes/app_routes.dart';
import '../../../core/models/ecommerce/product_category_model.dart';
import '../../../core/network/api_repository.dart';

class EcommerceHomeController extends GetxController {
  final _api = Get.find<ApiRepository>();
  final cartService = Get.find<EcommerceCartService>();

  final isLoading = false.obs;
  final error = RxnString();
  final categories = <ProductCategoryModel>[].obs;

  final bannerIndex = 0.obs;

  static const List<String> _fallbackBannerUrls = <String>[
    'https://images.unsplash.com/photo-1637647510982-f4e57955b2b3?auto=format&fit=crop&w=1400&q=80',
    'https://images.unsplash.com/photo-1652693018228-29548c4105ec?auto=format&fit=crop&w=1400&q=80',
    'https://images.unsplash.com/photo-1640817764181-5749e6bbbaf4?auto=format&fit=crop&w=1400&q=80',
    'https://images.unsplash.com/photo-1566579090262-51cde5ebe92e?auto=format&fit=crop&w=1400&q=80',
  ];
  final bannerUrls = <String>[].obs;

  final PageController bannerPageController = PageController();
  Timer? _bannerTimer;

  @override
  void onInit() {
    super.onInit();

    _loadOrganizationBanners();
    load();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) return;
      cartService.refreshCart();
      _startBannerAutoSlide();
    });
  }

  @override
  void onClose() {
    _bannerTimer?.cancel();
    bannerPageController.dispose();
    super.onClose();
  }

  Future<void> load() async {
    try {
      isLoading.value = true;
      error.value = null;
      _loadOrganizationBanners();
      final list = await _api.ecommerceCategories();
      categories.assignAll(list);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void openCategory(ProductCategoryModel c) {
    Get.toNamed(
      Routes.ecommerceProductList,
      arguments: {'categoryId': c.id, 'categoryName': c.name},
    );
  }

  void openCart() {
    Get.toNamed(Routes.ecommerceCart);
  }

  void openOrders() {
    Get.toNamed(Routes.ecommerceOrders);
  }

  void openCheckout() {
    Get.snackbar('Checkout', 'Ir a checkout');
  }

  void _startBannerAutoSlide() {
    _bannerTimer?.cancel();
    if (bannerUrls.length <= 1) return;

    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!bannerPageController.hasClients) return;

      final next = (bannerIndex.value + 1) % bannerUrls.length;
      bannerPageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void onBannerChanged(int index) {
    // ✅ update diferido para no chocar con build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) return;
      bannerIndex.value = index;
    });
  }

  void onBannerUserInteraction() {
    _startBannerAutoSlide();
  }

  void onBannerTap(int index) {
    Get.snackbar('Banner', 'Tap banner #${index + 1}');
  }

  void _loadOrganizationBanners() {
    final organization = AppStorage.getOrganization();
    final dynamicUrls = organization == null
        ? const <String>[]
        : _extractBannerUrls(organization);

    final nextUrls = dynamicUrls.isNotEmpty ? dynamicUrls : _fallbackBannerUrls;
    bannerUrls.assignAll(nextUrls);

    if (bannerIndex.value >= bannerUrls.length) {
      bannerIndex.value = 0;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!bannerPageController.hasClients) return;
      bannerPageController.jumpToPage(0);
      _startBannerAutoSlide();
    });
  }

  List<String> _extractBannerUrls(OrganizationResponse organization) {
    return organization.banners
        .map((item) => item.imageUrl.trim())
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
  }
}
