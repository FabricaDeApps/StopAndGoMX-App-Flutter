import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/ecommerce_cart_service.dart';

class CartBadgeButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CartBadgeButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final cartService = Get.find<EcommerceCartService>();

    return Obx(() {
      final count = cartService.cartCount.value;

      return IconButton(
        onPressed: onPressed,
        icon: Badge(
          label: Text('$count'),
          isLabelVisible: count > 0,
          child: const Icon(Icons.shopping_cart_outlined),
        ),
      );
    });
  }
}
