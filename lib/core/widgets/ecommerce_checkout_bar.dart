import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/utils/money.dart';
import 'package:stopandgo/routes/app_routes.dart';
import '../services/ecommerce_cart_service.dart';

class EcommerceCheckoutBar extends StatefulWidget {
  const EcommerceCheckoutBar({super.key});

  @override
  State<EcommerceCheckoutBar> createState() => _EcommerceCheckoutBarState();
}

class _EcommerceCheckoutBarState extends State<EcommerceCheckoutBar> {
  final _shown = false.obs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _shown.value = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Get.find<EcommerceCartService>();

    return Obx(() {
      final count = cartService.cartCount.value;
      final hasItems = count > 0;

      final double subtotal = cartService.subtotal is RxDouble
          ? (cartService.subtotal as RxDouble).value
          : (cartService.subtotal as double);

      final visible = hasItems && _shown.value;

      return AnimatedSlide(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        offset: visible ? Offset.zero : const Offset(0, 1),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: visible ? 1 : 0,
          child: SafeArea(
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
                          money(subtotal),
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
                      onPressed: hasItems
                          ? () {
                              Get.toNamed(Routes.ecommerceCart);
                            }
                          : null,
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('Pagar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
