import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:stopandgo/core/models/news/news_models.dart';
import 'package:stopandgo/modules/webview/webview_page.dart';

import 'news_controller.dart';

class NewsView extends GetView<NewsController> {
  const NewsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Noticias')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final error = controller.error.value;
        if (error != null &&
            error.isNotEmpty &&
            controller.items.isEmpty &&
            !controller.isRefreshingFilters.value) {
          return _EmptyState(
            icon: Icons.error_outline,
            title: 'No se pudieron cargar las noticias',
            message: error,
            onRetry: controller.refreshData,
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 200) {
                controller.loadMore();
              }
              return false;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              children: [
                _FiltersSection(controller: controller),
                const SizedBox(height: 16),
                if (controller.items.isEmpty)
                  _EmptyState(
                    icon: Icons.newspaper_outlined,
                    title: 'Sin noticias disponibles',
                    message:
                        'No encontramos noticias para los filtros seleccionados.',
                    onRetry: controller.refreshData,
                  )
                else
                  ...controller.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _NewsCard(
                        item: item,
                        onTap: () {
                          controller.markAsSeen(item);
                          if (item.articleUrl.trim().isEmpty) return;
                          Get.to(
                            () => AppWebViewPage(
                              title: item.sourceName.isNotEmpty
                                  ? item.sourceName
                                  : 'Noticia',
                              url: item.articleUrl,
                            ),
                          );
                        },
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
      }),
    );
  }
}

class _FiltersSection extends StatelessWidget {
  const _FiltersSection({required this.controller});

  final NewsController controller;

  @override
  Widget build(BuildContext context) {
    final prefs = controller.preferences.value;
    final sports = prefs?.sports ?? const <NewsPreferenceSport>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filtros',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (sports.isEmpty)
          const Text('No hay preferencias de deportes disponibles.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sports
                .map(
                  (sport) => FilterChip(
                    label: Text(
                      sport.label.isNotEmpty ? sport.label : sport.sport,
                    ),
                    selected: controller.selectedSports.contains(sport.sport),
                    onSelected: (_) => controller.toggleSport(sport.sport),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 8),
        Text(
          controller.effectiveSports.isEmpty
              ? 'Usando las preferencias por defecto del usuario.'
              : 'Feed activo: ${controller.effectiveSports.join(', ')}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.black54),
        ),
        if (controller.isRefreshingFilters.value) ...[
          const SizedBox(height: 10),
          const LinearProgressIndicator(minHeight: 2),
        ],
      ],
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.item, required this.onTap});

  final NewsItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cover = item.imageUrl.trim();

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cover.isNotEmpty)
              CachedNetworkImage(
                imageUrl: cover,
                height: 190,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 190,
                  color: theme.colorScheme.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                ),
                errorWidget: (_, __, ___) => _ImageFallback(theme: theme),
              )
            else
              _ImageFallback(theme: theme),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _MetaBadge(
                        text: _labelForSport(item.sport),
                        color: theme.colorScheme.primary.withOpacity(.12),
                        textColor: theme.colorScheme.primary,
                      ),
                      if (item.sourceName.trim().isNotEmpty)
                        _MetaBadge(
                          text: item.sourceName,
                          color: theme.colorScheme.surfaceContainerHighest,
                          textColor: theme.colorScheme.onSurfaceVariant,
                        ),
                      if (item.isSeen)
                        _MetaBadge(
                          text: 'Vista',
                          color: Colors.green.withOpacity(.12),
                          textColor: Colors.green.shade700,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (item.summary.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.summary,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _formatDate(item.publishedAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const Icon(Icons.open_in_new, size: 18),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return 'Sin fecha';
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  static String _labelForSport(String sport) {
    switch (sport) {
      case 'futbol_americano':
        return 'Futbol Americano';
      case 'flag_football':
        return 'Flag Football';
      case 'voleibol':
        return 'Voleibol';
      case 'futbol':
        return 'Futbol';
      case 'basquetbol':
        return 'Basquetbol';
      default:
        return sport;
    }
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({
    required this.text,
    required this.color,
    required this.textColor,
  });

  final String text;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.newspaper_rounded,
        size: 42,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final Future<void> Function() onRetry;

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
              onPressed: () => onRetry(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
