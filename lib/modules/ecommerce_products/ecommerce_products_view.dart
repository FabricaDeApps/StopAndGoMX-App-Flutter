import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/widgets/ecommerce_checkout_bar.dart';
import 'ecommerce_products_controller.dart';

class EcommerceProductsView extends GetView<EcommerceProductsController> {
  const EcommerceProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.categoryName),
        actions: [
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
                  Text(err, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () =>
                        controller.load(q: controller.searchCtrl.text),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final list = controller.products;

          return Column(
            children: [
              TextField(
                controller: controller.searchCtrl,
                onChanged: controller.onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Buscar producto...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: controller.searchCtrl.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: controller.clearSearch,
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: list.isEmpty
                    ? const Center(
                        child: Text('No hay productos en esta categoría.'),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            controller.load(q: controller.searchCtrl.text),
                        child: GridView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 8),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.62,
                              ),
                          itemCount: list.length,
                          itemBuilder: (_, index) {
                            final p = list[index];

                            final img = p.imageUrl;
                            final showFromPrice = p.minPriceCents > 0;
                            final priceText = showFromPrice
                                ? 'Desde \$${p.minPrice.toStringAsFixed(2)}'
                                : (p.activeVariants.isNotEmpty
                                      ? 'Ver opciones'
                                      : 'Sin precio');

                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.black12),
                                color: Colors.white,
                              ),
                              child: InkWell(
                                onTap: () => controller.openProduct(p),
                                borderRadius: BorderRadius.circular(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(14),
                                      ),
                                      child: SizedBox(
                                        height: 120,
                                        width: double.infinity,
                                        child: img == null
                                            ? Container(
                                                color: Colors.black12,
                                                alignment: Alignment.center,
                                                child: const Icon(
                                                  Icons
                                                      .image_not_supported_outlined,
                                                  size: 36,
                                                ),
                                              )
                                            : Image.network(
                                                img,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Container(
                                                      color: Colors.black12,
                                                      alignment:
                                                          Alignment.center,
                                                      child: const Icon(
                                                        Icons
                                                            .broken_image_outlined,
                                                        size: 36,
                                                      ),
                                                    ),
                                              ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.name,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              priceText,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            if (p.variantsCount > 0) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                '${p.variantsCount} variante${p.variantsCount == 1 ? '' : 's'}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],

                                            const SizedBox(height: 6),

                                            // 👇 LIMITAMOS chips para que no rompa el layout
                                            if (p.previewValues.isNotEmpty)
                                              SizedBox(
                                                height:
                                                    34, // ajusta a gusto: 28-38
                                                child: SingleChildScrollView(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  child: Row(
                                                    children: p.previewValues.map((
                                                      v,
                                                    ) {
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              right: 6,
                                                            ),
                                                        child: Chip(
                                                          label: Text(
                                                            v,
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 11,
                                                                ),
                                                          ),
                                                          visualDensity:
                                                              VisualDensity
                                                                  .compact,
                                                          materialTapTargetSize:
                                                              MaterialTapTargetSize
                                                                  .shrinkWrap,
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),
                                                ),
                                              ),

                                            const Spacer(),

                                            // CTA al fondo siempre visible
                                            if (p.activeVariants.length == 1)
                                              Obx(() {
                                                final loading =
                                                    controller.quickAdding[p
                                                        .id] ==
                                                    true;
                                                return SizedBox(
                                                  width: double.infinity,
                                                  height: 42,
                                                  child: ElevatedButton(
                                                    onPressed: loading
                                                        ? null
                                                        : () => controller
                                                              .quickAdd(p),
                                                    child: loading
                                                        ? const SizedBox(
                                                            width: 16,
                                                            height: 20,
                                                            child:
                                                                CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                ),
                                                          )
                                                        : const Text('Agregar'),
                                                  ),
                                                );
                                              })
                                            else
                                              SizedBox(
                                                width: double.infinity,
                                                height: 36,
                                                child: OutlinedButton(
                                                  onPressed: () =>
                                                      controller.openProduct(p),
                                                  child: const Text('Ver'),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
