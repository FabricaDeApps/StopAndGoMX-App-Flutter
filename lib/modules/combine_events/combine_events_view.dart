// lib/modules/combine/events/combine_events_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/routes/app_routes.dart';
import 'combine_events_controller.dart';

class CombineEventsView extends GetView<CombineEventsController> {
  const CombineEventsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Combine'),
        actions: [
          IconButton(
            tooltip: 'Refrescar',
            onPressed: controller.load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value != null) {
          return _ErrorState(
            message: controller.error.value!,
            onRetry: controller.load,
          );
        }

        return Column(
          children: [
            _FiltersBar(controller: controller),
            Expanded(
              child: Obx(() {
                final items = controller.events;
                if (items.isEmpty) {
                  return _EmptyState(onReload: controller.load);
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final e = items[i];
                    final when = _fmtDateTime(e.startsAt);
                    final cat = e.category?.name ?? '—';
                    final venue = e.venue?.name;

                    return Card(
                      child: ListTile(
                        onTap: () => controller.openEvent(e),
                        leading: const CircleAvatar(
                          child: Icon(Icons.assessment_outlined),
                        ),
                        title: Text(
                          e.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('$cat • $when'),
                            if (venue != null && venue.isNotEmpty)
                              Text('Sede: $venue'),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        );
      }),
      floatingActionButton: Obx(() {
        if (controller.userRole.value == 'player') {
          return const SizedBox.shrink();
        }

        return FloatingActionButton.extended(
          onPressed: () async {
            final created = await Get.toNamed(Routes.combineCreate);
            if (created != null) controller.load();
          },
          icon: const Icon(Icons.add),
          label: const Text('Nuevo'),
        );
      }),
    );
  }

  static String _fmtDateTime(DateTime? d) {
    if (d == null) return '—';
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$y-$m-$day $hh:$mm';
  }
}

class _FiltersBar extends StatelessWidget {
  final CombineEventsController controller;
  const _FiltersBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () => controller.pickFromDate(context),
              icon: const Icon(Icons.date_range),
              label: Obx(() {
                final d = controller.from.value;
                return Text(
                  d == null
                      ? 'Desde'
                      : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
                );
              }),
            ),
            OutlinedButton.icon(
              onPressed: () => controller.pickToDate(context),
              icon: const Icon(Icons.event),
              label: Obx(() {
                final d = controller.to.value;
                return Text(
                  d == null
                      ? 'Hasta'
                      : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
                );
              }),
            ),
            OutlinedButton.icon(
              onPressed: controller.clearFilters,
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Limpiar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onReload;
  const _EmptyState({required this.onReload});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 42),
            const SizedBox(height: 10),
            const Text('Sin combines para mostrar'),
            const SizedBox(height: 12),
            FilledButton(onPressed: onReload, child: const Text('Recargar')),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 42),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
