import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/config/flavor_config.dart';
import 'package:stopandgo/core/widgets/ecommerce_checkout_bar.dart';
import 'ecommerce_home_controller.dart';

class EcommerceHomeView extends GetView<EcommerceHomeController> {
  const EcommerceHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final storeName = FlavorConfig.I.appName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tienda'),
        actions: [
          IconButton(
            onPressed: controller.openOrders,
            tooltip: 'Mis pedidos',
            icon: const Icon(Icons.receipt_long_outlined),
          ),
          Obx(() {
            final count = controller.cartService.cartCount.value;

            return IconButton(
              onPressed: controller.openCart,
              icon: Badge(
                label: Text('$count'),
                isLabelVisible: true,
                child: const Icon(Icons.shopping_cart_outlined),
              ),
            );
          }),
        ],
      ),
      bottomNavigationBar: EcommerceCheckoutBar(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final err = controller.error.value;
          if (err != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    err,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: controller.load,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final list = controller.categories;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenido a la tienda de $storeName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Selecciona una categoría para ver los productos.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: list.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('No hay categorías disponibles.'),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: controller.load,
                              child: const Text('Actualizar'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => controller.load(),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: list.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final c = list[index];
                            return InkWell(
                              onTap: () => controller.openCategory(c),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.black12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        c.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),

              const SizedBox(height: 14),

              // ✅ Slider de banners + dots (abajo)
              _BannersSlider(controller: controller),
            ],
          );
        }),
      ),
    );
  }
}

class _BannersSlider extends StatelessWidget {
  final EcommerceHomeController controller;
  const _BannersSlider({required this.controller});

  @override
  Widget build(BuildContext context) {
    final urls = controller.bannerUrls;
    if (urls.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 150,
            width: double.infinity,
            child: PageView.builder(
              controller: controller.bannerPageController,
              itemCount: urls.length,
              onPageChanged: controller.onBannerChanged,
              itemBuilder: (context, index) {
                final url = urls[index];
                return GestureDetector(
                  onTap: () => controller.onBannerTap(index),
                  onPanDown: (_) => controller.onBannerUserInteraction(),
                  child: Image.network(url, fit: BoxFit.cover),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Obx(
          () => _Dots(
            count: urls.length,
            activeIndex: controller.bannerIndex.value,
          ),
        ),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int activeIndex;

  const _Dots({required this.count, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: isActive ? 18 : 8,
          decoration: BoxDecoration(
            color: isActive ? Colors.black87 : Colors.black26,
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}
