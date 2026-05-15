import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppNavigator {
  static Future<bool> maybePop<T extends Object?>(
    BuildContext context, {
    T? result,
  }) {
    return Navigator.of(context).maybePop<T>(result);
  }

  static bool pop<T extends Object?>({BuildContext? context, T? result}) {
    final navigator = context != null ? Navigator.of(context) : Get.key.currentState;
    if (navigator == null || !navigator.canPop()) {
      return false;
    }

    navigator.pop<T>(result);
    return true;
  }
}
