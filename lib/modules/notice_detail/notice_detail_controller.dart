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

  bool get hasExternalUrl {
    final value = (notice.value?.externalUrl ?? '').trim();
    return value.isNotEmpty;
  }

  Future<void> openAttachment() async {
    final attachment = (notice.value?.attachment ?? '').trim();
    if (attachment.isEmpty) return;

    await _openUrl(
      attachment,
      invalidMessage: 'URL inválida del adjunto',
      cannotOpenMessage: 'No se pudo abrir el archivo adjunto',
    );
  }

  Future<void> openExternalUrl() async {
    final url = (notice.value?.externalUrl ?? '').trim();
    if (url.isEmpty) return;

    await _openUrl(
      url,
      invalidMessage: 'URL inválida del enlace',
      cannotOpenMessage: 'No se pudo abrir el enlace externo',
    );
  }

  Future<void> _openUrl(
    String rawUrl, {
    required String invalidMessage,
    required String cannotOpenMessage,
  }) async {
    final normalizedUrl = rawUrl.trim();
    if (normalizedUrl.isEmpty) return;

    final uri = Uri.tryParse(normalizedUrl);
    if (uri == null) {
      Get.snackbar(
        'Error',
        '$invalidMessage:\n$normalizedUrl',
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
          '$cannotOpenMessage:\n$normalizedUrl',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final ok = await launchUrl(uri, mode: mode);
      if (!ok) {
        Get.snackbar(
          'Error',
          cannotOpenMessage,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        '$cannotOpenMessage: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
