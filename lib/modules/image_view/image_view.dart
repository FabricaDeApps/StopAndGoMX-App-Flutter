// lib/modules/image_view/image_view.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'image_controller.dart';

class ImageView extends GetView<ImageController> {
  const ImageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Comprobante', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: controller.hasUrl
            ? InteractiveViewer(
                minScale: 0.5,
                maxScale: 5,
                child: CachedNetworkImage(
                  imageUrl: controller.url,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white70,
                    size: 64,
                  ),
                ),
              )
            : const Text('Sin imagen', style: TextStyle(color: Colors.white70)),
      ),
    );
  }
}
