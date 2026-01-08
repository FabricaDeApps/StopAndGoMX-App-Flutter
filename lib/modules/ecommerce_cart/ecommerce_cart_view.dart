import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'ecommerce_cart_controller.dart';

class EcommerceCartView extends GetView<EcommerceCartController> {
  const EcommerceCartView({super.key});

  static final _money = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 2,
  );

  String? _imageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    const base = 'https://stopandgomx.app/storage/';
    return '$base$path';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi carrito'),
        actions: [
          Obx(() {
            final isDisabled =
                controller.isClearing.value || controller.isLoading.value;
            return IconButton(
              onPressed: isDisabled ? null : controller.clearCart,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Vaciar carrito',
            );
          }),
        ],
      ),
      bottomNavigationBar: Obx(() {
        final count = controller.cartService.cartCount.value;
        final subtotal = controller.cartService.subtotal.value;

        if (count <= 0) return const SizedBox.shrink();

        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: const Border(top: BorderSide(color: Colors.black12)),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 16,
                  offset: Offset(0, -6),
                  color: Color(0x14000000),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subtotal · $count artículo${count == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _money.format(subtotal),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: controller.checkout,
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Finalizar compra'),
                  ),
                ),
              ],
            ),
          ),
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

          final cart = controller.cart.value;
          final items = cart?.items ?? const [];

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    size: 44,
                    color: Colors.black38,
                  ),
                  const SizedBox(height: 10),
                  const Text('Tu carrito está vacío.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Seguir comprando'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: controller.load,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final it = items[i];

                final title = (it.variantTitleAtAdd?.isNotEmpty ?? false)
                    ? it.variantTitleAtAdd!
                    : 'Producto';

                final img = it.variant?.imageUrl;
                final isUpdating = controller.updatingItemIds.contains(it.id);
                final unit = it.unitPrice;
                final line = it.lineTotal;

                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black12),
                    color: Colors.white,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            height: 70,
                            width: 70,
                            child: img == null
                                ? Container(
                                    color: Colors.black12,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.image_not_supported_outlined,
                                    ),
                                  )
                                : Image.network(
                                    img,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.black12,
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.broken_image_outlined,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),

                              Text(
                                '${_money.format(unit)} c/u',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 6),

                              Text(
                                _money.format(line),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),

                              const SizedBox(height: 10),

                              Row(
                                children: [
                                  _QtyButton(
                                    icon: Icons.remove,
                                    onPressed: isUpdating
                                        ? null
                                        : () => controller.dec(it),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Text(
                                      '${it.qty}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  _QtyButton(
                                    icon: Icons.add,
                                    onPressed: isUpdating
                                        ? null
                                        : () => controller.inc(it),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: isUpdating
                                        ? null
                                        : () => controller.removeItem(it),
                                    icon: const Icon(Icons.delete_outline),
                                    tooltip: 'Eliminar',
                                  ),
                                ],
                              ),

                              if (isUpdating)
                                const Padding(
                                  padding: EdgeInsets.only(top: 6),
                                  child: LinearProgressIndicator(minHeight: 2),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _QtyButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      width: 34,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}
