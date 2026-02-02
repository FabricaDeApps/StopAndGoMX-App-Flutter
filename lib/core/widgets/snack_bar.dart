import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UiSnackbar {
  static void success(String title, String message) {
    _show(
      title,
      message,
      background: Get.theme.colorScheme.primary,
      icon: Icons.check_circle_outline,
    );
  }

  static void error(String title, String message) {
    _show(
      title,
      message,
      background: Colors.redAccent,
      icon: Icons.error_outline,
    );
  }

  static void info(String title, String message) {
    _show(title, message, background: Colors.black87, icon: Icons.info_outline);
  }

  static void _show(
    String title,
    String message, {
    required Color background,
    required IconData icon,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: background,
      colorText: Colors.white,
      icon: Icon(icon, color: Colors.white),
      margin: const EdgeInsets.all(12),
      borderRadius: 14,
      isDismissible: true,
      duration: const Duration(seconds: 3),
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeIn,
    );
  }
}
