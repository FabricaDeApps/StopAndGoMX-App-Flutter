import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/combines/combine_event_results_response.dart';
import 'package:stopandgo/core/models/combines/combine_metric.dart';
import 'combine_event_results_controller.dart';

class CombineEventResultsView extends GetView<CombineEventResultsController> {
  const CombineEventResultsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final e = controller.event.value;
          return Text(e == null ? 'Resultados' : 'Resultados • ${e.name}');
        }),
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

        final items = controller.results;
        if (items.isEmpty) {
          return const _EmptyState();
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _ResultCard(result: items[i]),
        );
      }),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final CombineEventResult result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final when = _fmtDateTime(result.measuredAt);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person_outline)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    result.player.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (result.overallScore != null)
                  _ScorePill(score: result.overallScore!),
              ],
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(Icons.event, when),
                if (result.checkedBy != null)
                  _chip(Icons.verified_user, 'Rev: ${result.checkedBy}'),
              ],
            ),

            const SizedBox(height: 10),

            // Valores por métrica
            if (result.values.isEmpty)
              Text('Sin valores.', style: theme.textTheme.bodyMedium)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: result.values.map((v) {
                  final metric = v.metric;
                  final valText = _formatMetricValue(metric, v);
                  return Chip(
                    label: Text('${metric.name}: $valText'),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),

            if ((result.notes ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(result.notes!.trim(), style: theme.textTheme.bodyMedium),
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

  static String _formatMetricValue(CombineMetric m, CombineEventResultValue v) {
    // prioridad: value_text si existe, si no, number
    if ((v.valueText ?? '').trim().isNotEmpty) {
      final u = (m.unit ?? '').trim();
      return u.isEmpty ? v.valueText!.trim() : '${v.valueText!.trim()} $u';
    }

    final n = v.valueNumber;
    if (n == null) return '—';

    final d = m.decimals ?? 0;
    final numTxt = n.toStringAsFixed(d);
    final u = (m.unit ?? '').trim();
    return u.isEmpty ? numTxt : '$numTxt $u';
  }

  static String _fmtDateTime(DateTime? d) {
    if (d == null) return '—';
    // Formato simple
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$y-$m-$day $hh:$mm';
  }
}

class _ScorePill extends StatelessWidget {
  final double score;
  const _ScorePill({required this.score});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Text(
        'Score ${score.toStringAsFixed(2)}',
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
            const Text('Todavía no hay resultados capturados'),
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
