import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:stopandgo/core/config/flavor_config.dart';
import 'splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = controller.isLoading.value;
      final error = controller.error.value;
      final primary = controller.primaryColor.value;
      final secondary = controller.secondaryColor.value;
      final url = controller.imageUrl.value;

      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primary, secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Image.asset(
              'assets/images/logo_generic.png',
              width: 160,
              height: 160,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    });
  }
}
