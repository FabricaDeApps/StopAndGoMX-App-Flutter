import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/utils/ecommerce_price_formatter.dart';
import 'package:stopandgo/core/widgets/ecommerce_checkout_bar.dart';
import 'package:stopandgo/routes/app_routes.dart';
import '../../../core/models/ecommerce/product_detail_model.dart';
import 'ecommerce_product_detail_controller.dart';

class EcommerceProductDetailView
    extends GetView<EcommerceProductDetailController> {
  const EcommerceProductDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Producto'),
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
      bottomNavigationBar: Obx(() {
        final adding = controller.isAdding.value;
        final resolving = controller.isResolving.value;
        final canAdd = controller.canAddToCart && !resolving;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SafeArea(
              top: false,
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: adding || !canAdd ? null : controller.addToCart,
                    icon: adding || resolving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.shopping_cart_checkout),
                    label: Text(
                      adding
                          ? 'Agregando...'
                          : resolving
                              ? 'Validando selección...'
                              : 'Agregar al carrito',
                    ),
                  ),
                ),
              ),
            ),
            const EcommerceCheckoutBar(),
          ],
        );
      }),
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
                    onPressed: controller.load,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final p = controller.product.value;
          if (p == null) {
            return const Center(child: Text('Producto no disponible.'));
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 230,
                  child: (p.imageUrl == null)
                      ? Container(
                          color: Colors.white,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            size: 48,
                          ),
                        )
                      : Container(
                          color: Colors.white,
                          alignment: Alignment.center,
                          child: Image.network(
                            p.imageUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image_outlined,
                              size: 48,
                            ),
                          ),
                        ),
                ),
              ),
              if (p.imageUrl != null && p.imageUrl!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => Get.toNamed(
                      Routes.imageView,
                      arguments: {'url': p.imageUrl},
                    ),
                    icon: const Icon(Icons.open_in_full, size: 18),
                    label: const Text('Ver imagen grande'),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Text(
                p.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (p.description != null &&
                  p.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  p.description!,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
              const SizedBox(height: 18),
              if (controller.usesAttributeSelection) ...[
                const Text(
                  'Selecciona tus opciones',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                ...p.attributeGroups.map(
                  (group) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _AttributeGroupSection(
                      group: group,
                      controller: controller,
                    ),
                  ),
                ),
              ] else ...[
                const Text(
                  'Selecciona una variante',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Obx(() {
                  final selected = controller.selectedVariantId.value;

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: p.variants.map((v) {
                      final isSelected = selected == v.id;
                      final label =
                          v.title.isNotEmpty ? v.title : v.values.join(' / ');
                      final price = v.hasDisplayPrice
                          ? formatEcommercePrice(
                              currency: v.displayCurrency,
                              amount: v.displayAmount,
                            )
                          : 'Sin precio';

                      return ChoiceChip(
                        selected: isSelected,
                        onSelected: (_) => controller.selectVariant(v.id),
                        label: Text('$label  •  $price'),
                      );
                    }).toList(),
                  );
                }),
              ],
              const SizedBox(height: 4),
              Obx(() {
                final variant = controller.selectedVariant;
                final usesAttributes = controller.usesAttributeSelection;

                if (variant == null) {
                  final text = usesAttributes
                      ? 'Elige todos los atributos para ver precio y disponibilidad.'
                      : 'Selecciona una variante para ver precio y disponibilidad.';
                  return Text(
                    text,
                    style: const TextStyle(color: Colors.black54),
                  );
                }

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        variant.title.isEmpty ? p.name : variant.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        variant.hasDisplayPrice
                            ? formatEcommercePrice(
                                currency: variant.displayCurrency,
                                amount: variant.displayAmount,
                              )
                            : 'Sin precio',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        variant.stock > 0
                            ? 'Disponible: ${variant.stock}'
                            : 'Agotado',
                        style: TextStyle(
                          color:
                              variant.stock > 0 ? Colors.black54 : Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 18),
              const Text(
                'Cantidad',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  IconButton(
                    onPressed: controller.decQty,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Obx(
                    () => Text(
                      '${controller.qty.value}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: controller.incQty,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _AttributeGroupSection extends StatelessWidget {
  final ProductAttributeGroupModel group;
  final EcommerceProductDetailController controller;

  const _AttributeGroupSection({
    required this.group,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedValueId = controller.selectedValueIdsByGroup[group.id];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: group.values.map((value) {
              return ChoiceChip(
                selected: selectedValueId == value.id,
                onSelected: (_) => controller.selectAttributeValue(
                  groupId: group.id,
                  valueId: value.id,
                ),
                label: Text(value.label),
              );
            }).toList(),
          ),
        ],
      );
    });
  }
}
