// lib/modules/home/tabs/notices/notices_tab_view.dart
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'notices_tab_controller.dart';

class NoticesTabView extends GetView<NoticesTabController> {
  const NoticesTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final list = controller.listNotices;
      if (list.isEmpty) {
        return Center(
          child: Text('Sin avisos', style: theme.textTheme.bodyMedium),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final notice = list[i];

          String title = "";
          if (notice.categoryId != null) {
            title = "${notice.title} - ${notice.categoryName}";
          } else {
            title = notice.title;
          }

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withOpacity(.12),
                child: const Icon(Icons.campaign_outlined),
              ),
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    _fmtDateTime(notice.publishedAt!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if ((notice.message ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      notice.message!.trim(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
              trailing:
                  (notice.attachment != null &&
                      notice.attachment!.trim().isNotEmpty)
                  ? const Icon(Icons.chevron_right)
                  : null,
              onTap: () async {
                final attachment = (notice.attachment ?? '').trim();

                if (attachment.isNotEmpty) {
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

                  return;
                }

                // Si no hay attachment, por ahora no hace nada.
                // Si luego haces NoticeDetail, aquí navegas.
              },
            ),
          );
        },
      );
    });
  }

  static String _fmtDateTime(DateTime d) {
    final two = (int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }
}
