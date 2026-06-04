import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'notice_detail_controller.dart';

class NoticeDetailView extends GetView<NoticeDetailController> {
  const NoticeDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final n = controller.notice.value;
      if (n == null) {
        return Scaffold(
          appBar: AppBar(title: Text('Detalle de aviso')),
          body: Center(child: Text('Aviso no disponible')),
        );
      }

      return Scaffold(
        appBar: AppBar(title: const Text('Detalle de aviso')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if ((n.categoryName ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Categoría: ${n.categoryName}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mensaje',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (n.message ?? '').trim().isEmpty
                          ? 'Sin mensaje'
                          : n.message!.trim(),
                    ),
                  ],
                ),
              ),
            ),
            if ((n.image ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  title: const Text('Imagen'),
                  subtitle: Text(n.image!.trim()),
                ),
              ),
            ],
            if (controller.hasAttachment) ...[
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Adjunto',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () async {
                            await controller.openAttachment();
                          },
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Abrir adjunto'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (controller.hasExternalUrl) ...[
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enlace',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () async {
                            await controller.openExternalUrl();
                          },
                          icon: const Icon(Icons.link_outlined),
                          label: const Text('Abrir enlace'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}
