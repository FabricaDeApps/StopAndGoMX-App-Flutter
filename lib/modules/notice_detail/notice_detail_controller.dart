import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:stopandgo/core/models/dto/notice_model.dart';

class NoticeDetailController extends GetxController {
  final notice = Rxn<Notice>();

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments?['notice'];
    if (arg is Notice) {
      notice.value = arg;
    }
  }

  bool get hasAttachment {
    final value = (notice.value?.attachment ?? '').trim();
    return value.isNotEmpty;
  }

  Future<void> openAttachment() async {
    final attachment = (notice.value?.attachment ?? '').trim();
    if (attachment.isEmpty) return;

    final uri = Uri.tryParse(attachment);
    if (uri == null) {
      Get.snackbar(
        'Error',
        'URL inválida:\n$attachment',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    LaunchMode mode;
    if (kIsWeb) {
      mode = LaunchMode.platformDefault;
    } else if (Platform.isAndroid || Platform.isIOS) {
      mode = LaunchMode.externalApplication;
    } else {
      mode = LaunchMode.platformDefault;
    }

    try {
      final can = await canLaunchUrl(uri);
      if (!can) {
        Get.snackbar(
          'Error',
          'No se pudo abrir el archivo adjunto:\n$attachment',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final ok = await launchUrl(uri, mode: mode);
      if (!ok) {
        Get.snackbar(
          'Error',
          'No se pudo abrir el archivo adjunto',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo abrir el archivo adjunto: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
