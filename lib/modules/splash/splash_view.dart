import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Builder(
                builder: (_) {
                  if (isLoading) {
                    return const SizedBox(
                      width: 52,
                      height: 52,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    );
                  }

                  if (error != null) {
                    return Text(
                      error,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    );
                  }

                  if (url != null && url.isNotEmpty) {
                    // cacheKey ayuda a evitar problemas de querystrings/cdn
                    final cacheKey = url; // si tienes un updatedAt úsalo aquí

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: url,
                        width: 260,
                        height: 260,
                        fit: BoxFit.contain,
                        fadeInDuration: const Duration(milliseconds: 250),
                        placeholder: (context, _) => const SizedBox(
                          width: 52,
                          height: 52,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                        errorWidget: (context, _, __) => const Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.white,
                          size: 64,
                        ),
                        imageBuilder: (context, imageProvider) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            controller.markImageShown();
                          });
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image(
                              image: imageProvider,
                              fit: BoxFit.contain,
                            ),
                          );
                        },
                      ),
                    );
                  }

                  return const Icon(
                    Icons.sports_football,
                    color: Colors.white,
                    size: 64,
                  );
                },
              ),
            ),
          ),
        ),
      );
    });
  }
}
