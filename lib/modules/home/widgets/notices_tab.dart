import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../home_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class NoticesTab extends StatelessWidget {
  const NoticesTab({super.key, required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      if (controller.isLoadingNotices.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final list = controller.notices;
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
          final n = list[i];
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
                n.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    _fmtDateTime(n.date),
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if ((n.message ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      n.message!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
              trailing: (n.attachment != null && n.attachment!.isNotEmpty)
                  ? const Icon(Icons.chevron_right)
                  : null,
              onTap: () async {
                final attachment = n.attachment;

                // Si hay attachment, intentamos abrirlo
                if (attachment != null && attachment.isNotEmpty) {
                  final url = attachment.trim();
                  debugPrint('Intentando abrir attachment: $url');

                  final uri = Uri.parse(url);

                  // Modo de apertura según plataforma
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
                    debugPrint('canLaunchUrl($uri) = $can');

                    if (can) {
                      final ok = await launchUrl(uri, mode: mode);
                      if (!ok) {
                        Get.snackbar(
                          'Error',
                          'No se pudo abrir el archivo adjunto',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      }
                    } else {
                      Get.snackbar(
                        'Error',
                        'No se pudo abrir el archivo adjunto:\n$url',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  } catch (e) {
                    print(e);
                  }
                } else {
                  // Sin attachment -> flujo normal
                  controller.onTapNotice(n);
                }
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
