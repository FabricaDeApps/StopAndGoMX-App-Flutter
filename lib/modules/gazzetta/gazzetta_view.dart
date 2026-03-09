import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/gazzetta/gazetta_item.dart';
import 'package:stopandgo/routes/app_routes.dart';

import 'gazzetta_controller.dart';

class GazzettaView extends GetView<GazzettaController> {
  final bool embedded;

  const GazzettaView({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final body = Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.isModuleUnavailable.value) {
        return _EmptyState(
          icon: Icons.block_outlined,
          title: 'Módulo no disponible',
          message: 'Esta organización no tiene Gazzetta habilitada.',
          onRetry: controller.refreshData,
        );
      }

      final error = controller.error.value;
      if (error != null && error.isNotEmpty) {
        return _EmptyState(
          icon: Icons.error_outline,
          title: 'No se pudo cargar',
          message: error,
          onRetry: controller.refreshData,
        );
      }

      final feed = controller.feed.value;
      final history = controller.history;
      if (feed == null && history.isEmpty) {
        return _EmptyState(
          icon: Icons.menu_book_outlined,
          title: 'Sin gazzettas',
          message: 'Aún no hay contenido publicado.',
          onRetry: controller.refreshData,
        );
      }

      return RefreshIndicator(
        onRefresh: controller.refreshData,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
              controller.loadMore();
            }
            return false;
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              if (feed != null) ...[
                Text(
                  'Última gazzetta',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _GazettaCard(
                  item: feed.item,
                  onTap: () => Get.toNamed(
                    Routes.gazzettaDetail,
                    arguments: {'id': feed.id},
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Text(
                'Histórico',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...history.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _GazettaCard(
                    item: item,
                    onTap: () => Get.toNamed(
                      Routes.gazzettaDetail,
                      arguments: {'id': item.id},
                    ),
                  ),
                ),
              ),
              if (controller.isLoadingMore.value)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      );
    });

    if (embedded) return body;

    return Scaffold(
      appBar: AppBar(title: const Text('Gazzetta')),
      body: body,
    );
  }
}

class _GazettaCard extends StatelessWidget {
  final GazettaItem item;
  final VoidCallback onTap;

  const _GazettaCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(.12),
          child: const Icon(Icons.menu_book_rounded),
        ),
        title: Text(
          item.subject ?? 'Gazzetta #${item.id}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(_dateLabel(item.publishedAt ?? item.weekStart)),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  String _dateLabel(DateTime? date) {
    if (date == null) return 'Sin fecha';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 38),
            const SizedBox(height: 10),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
