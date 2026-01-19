// lib/modules/combine/detail/combine_event_detail_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'combine_event_detail_controller.dart';

class CombineEventDetailView extends GetView<CombineEventDetailController> {
  const CombineEventDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluación'),
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

        final e = controller.event.value;
        if (e == null) {
          return _ErrorState(message: 'Sin datos', onRetry: controller.load);
        }

        final metrics = controller.metrics;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            _EventHeaderCard(
              name: e.name,
              categoryName: e.category?.name,
              seasonName: e.season?.name,
              venueName: e.venue?.name,
              startsAt: e.startsAt,
              endsAt: e.endsAt,
              notes: e.notes,
              resultsCount: controller.resultsCount.value,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Text(
                    'Métricas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${metrics.length}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (metrics.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('No hay métricas configuradas.')),
              )
            else
              ...metrics.map(
                (m) => _MetricCard(
                  name: m.name,
                  keyName: m.key,
                  unit: m.unit,
                  type: m.type,
                  direction: m.direction,
                  decimals: m.decimals,
                  isActive: m.isActive,
                  onTap: () => controller.goLeaderboard(m),
                ),
              ),

            const SizedBox(height: 90), // espacio para el FAB
          ],
        );
      }),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ===== BOTÓN VER RESULTADOS =====
          SizedBox(
            width: 180,
            child: FilledButton.icon(
              onPressed: controller.goResults,
              icon: const Icon(Icons.leaderboard),
              label: const Text('Ver resultados'),
            ),
          ),
          const SizedBox(height: 10),

          // ===== FAB CAPTURAR =====
          FloatingActionButton.extended(
            onPressed: controller.goCapture,
            icon: const Icon(Icons.edit_note),
            label: const Text('Capturar resultados'),
          ),
        ],
      ),
    );
  }
}

/* =======================
 * UI Widgets
 * ======================= */

class _EventHeaderCard extends StatelessWidget {
  final String name;
  final String? categoryName;
  final String? seasonName;
  final String? venueName;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String? notes;
  final int resultsCount;

  const _EventHeaderCard({
    required this.name,
    required this.categoryName,
    required this.seasonName,
    required this.venueName,
    required this.startsAt,
    required this.endsAt,
    required this.notes,
    required this.resultsCount,
  });

  @override
  Widget build(BuildContext context) {
    final when = _fmtRange(startsAt, endsAt);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(Icons.groups_2, categoryName ?? '—'),
                if ((seasonName ?? '').isNotEmpty)
                  _chip(Icons.calendar_month, seasonName!),
                if ((venueName ?? '').isNotEmpty)
                  _chip(Icons.place_outlined, venueName!),
                _chip(Icons.event, when),
                _chip(Icons.how_to_reg, 'Resultados: $resultsCount'),
              ],
            ),
            if ((notes ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(notes!, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _chip(IconData icon, String text) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(text),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  static String _fmtRange(DateTime? s, DateTime? e) {
    if (s == null) return '—';
    final sTxt = _fmtDT(s);
    if (e == null) return sTxt;
    return '$sTxt → ${_fmtDT(e)}';
  }

  static String _fmtDT(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$y-$m-$day $hh:$mm';
  }
}

class _MetricCard extends StatelessWidget {
  final String name;
  final String keyName;
  final String? unit;
  final String? type;
  final String? direction;
  final int? decimals;
  final bool isActive;
  final VoidCallback onTap;

  const _MetricCard({
    required this.name,
    required this.keyName,
    required this.unit,
    required this.type,
    required this.direction,
    required this.decimals,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sub = [
      if ((unit ?? '').isNotEmpty) 'Unidad: $unit',
      if ((type ?? '').isNotEmpty) 'Tipo: $type',
      if ((direction ?? '').isNotEmpty)
        direction == 'higher_is_better' ? '↑ mejor' : '↓ mejor',
      if (decimals != null) 'Dec: $decimals',
      if (!isActive) 'INACTIVA',
    ].join(' • ');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          child: Text(
            name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'M',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('$keyName\n$sub'),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
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
