// lib/modules/combine/results/create/combine_result_create_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/combines/combine_metric.dart';
import 'combine_result_create_controller.dart';

class CombineResultCreateView extends GetView<CombineResultCreateController> {
  const CombineResultCreateView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(controller.eventName.value ?? 'Capturar resultados'),
        ),
        actions: [
          IconButton(
            tooltip: 'Refrescar',
            onPressed: () {
              controller.load();
              controller.loadMetrics();
              controller.loadPlayers();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value != null && controller.allMetrics.isEmpty) {
          return _ErrorState(
            message: controller.error.value!,
            onRetry: () {
              controller.load();
              controller.loadMetrics();
              controller.loadPlayers();
            },
          );
        }

        return Form(
          key: controller.formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _SectionCard(
                title: 'Jugador',
                child: Column(
                  children: [
                    Obx(() {
                      if (controller.isLoadingPlayers.value) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: LinearProgressIndicator(),
                        );
                      }

                      return FormField<int>(
                        key: controller.playerFieldKey,
                        validator: (_) {
                          final pid = controller.selectedPlayerId();
                          if (pid == null || pid <= 0)
                            return 'Selecciona un jugador';
                          return null;
                        },
                        builder: (state) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RawAutocomplete<Map<String, dynamic>>(
                                textEditingController:
                                    controller.playerSearchCtrl,
                                focusNode: controller.playerFocus,
                                displayStringForOption: controller.playerLabel,
                                optionsBuilder: (TextEditingValue value) {
                                  final q = value.text;
                                  if (q.trim().isEmpty)
                                    return controller.players.take(25);
                                  final filtered = controller.players.where(
                                    (p) => controller.matchesPlayer(p, q),
                                  );
                                  return filtered.take(50);
                                },
                                onSelected: (p) {
                                  controller.selectedPlayer.value = p;
                                  controller.playerSearchCtrl.text = controller
                                      .playerLabel(p);
                                  controller.playerFocus.unfocus();
                                },
                                fieldViewBuilder:
                                    (
                                      context,
                                      textCtrl,
                                      focusNode,
                                      onFieldSubmitted,
                                    ) {
                                      return TextFormField(
                                        controller: textCtrl,
                                        focusNode: focusNode,
                                        decoration: InputDecoration(
                                          labelText: 'Jugador',
                                          hintText:
                                              'Buscar por nombre, id o # jersey',
                                          prefixIcon: const Icon(
                                            Icons.person_outline,
                                          ),
                                          border: const OutlineInputBorder(),
                                          suffixIcon: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (controller
                                                      .selectedPlayer
                                                      .value !=
                                                  null)
                                                IconButton(
                                                  tooltip: 'Limpiar',
                                                  onPressed: () {
                                                    controller
                                                            .selectedPlayer
                                                            .value =
                                                        null;
                                                    controller.playerSearchCtrl
                                                        .clear();
                                                    controller.playerFocus
                                                        .requestFocus();
                                                  },
                                                  icon: const Icon(Icons.clear),
                                                ),
                                              IconButton(
                                                tooltip: 'Recargar',
                                                onPressed:
                                                    controller.loadPlayers,
                                                icon: const Icon(Icons.refresh),
                                              ),
                                            ],
                                          ),
                                        ),
                                        validator: (_) {
                                          final pid = controller
                                              .selectedPlayerId();
                                          if (pid == null || pid <= 0)
                                            return 'Selecciona un jugador';
                                          return null;
                                        },
                                        onChanged: (_) =>
                                            controller.selectedPlayer.value =
                                                null,
                                      );
                                    },
                                optionsViewBuilder:
                                    (context, onSelected, options) {
                                      return Align(
                                        alignment: Alignment.topLeft,
                                        child: Material(
                                          elevation: 6,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxHeight: 320,
                                              maxWidth: 520,
                                            ),
                                            child: ListView.builder(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 6,
                                                  ),
                                              itemCount: options.length,
                                              itemBuilder: (context, index) {
                                                final p = options.elementAt(
                                                  index,
                                                );
                                                final label = controller
                                                    .playerLabel(p);
                                                final jersey =
                                                    p['jersey_number'];

                                                return ListTile(
                                                  dense: true,
                                                  leading: CircleAvatar(
                                                    child: Text(
                                                      (jersey != null &&
                                                              jersey
                                                                  .toString()
                                                                  .isNotEmpty)
                                                          ? '$jersey'
                                                          : 'P',
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                                  title: Text(
                                                    label,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  subtitle: Text(
                                                    'ID: ${p['id']}',
                                                  ),
                                                  onTap: () => onSelected(p),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                              ),
                              const SizedBox(height: 8),
                              Obx(() {
                                final p = controller.selectedPlayer.value;
                                if (p == null) return const SizedBox.shrink();
                                return Row(
                                  children: [
                                    const Icon(Icons.check_circle, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Seleccionado: ${controller.playerLabel(p)}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          );
                        },
                      );
                    }),
                    const SizedBox(height: 12),
                    Obx(() {
                      final dt = controller.measuredAt.value;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.schedule),
                        title: const Text('Medido en'),
                        subtitle: Text(_fmtDT(dt) ?? 'Seleccionar'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => controller.pickMeasuredAt(context),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              _SectionCard(
                title: 'Notas y score',
                child: Column(
                  children: [
                    TextFormField(
                      controller: controller.overallScoreCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Overall score (opcional)',
                        hintText: '88.5',
                        prefixIcon: Icon(Icons.emoji_events_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if ((v ?? '').trim().isEmpty) return null;
                        final d = double.tryParse((v ?? '').trim());
                        if (d == null) return 'Score inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: controller.notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notas (opcional)',
                        hintText: 'Buen día',
                        prefixIcon: Icon(Icons.notes),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Métricas',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Obx(() => Text('${controller.selectedMetricKeys.length}')),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => controller.openMetricPicker(context),
                    icon: const Icon(Icons.tune),
                    label: const Text('Elegir'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Crear métrica',
                    onPressed: controller.goCreateMetric,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Obx(() {
                final list = controller.selectedMetrics;
                if (list.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Selecciona al menos una métrica para capturar valores.',
                    ),
                  );
                }

                return Column(
                  children: list.map((m) {
                    final ctrl = controller.valueCtrls[m.key];
                    if (ctrl == null) return const SizedBox.shrink();
                    return _MetricInput(metric: m, controller: ctrl);
                  }).toList(),
                );
              }),

              const SizedBox(height: 12),

              Obx(() {
                final err = controller.error.value;
                if (err == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(err, style: const TextStyle(color: Colors.red)),
                );
              }),

              Obx(() {
                return SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: controller.isSaving.value
                        ? null
                        : controller.submit,
                    icon: controller.isSaving.value
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      controller.isSaving.value ? 'Guardando...' : 'Guardar',
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }),
    );
  }

  static String? _fmtDT(DateTime? d) {
    if (d == null) return null;
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$y-$m-$day $hh:$mm';
  }
}

class _MetricInput extends StatelessWidget {
  final CombineMetric metric;
  final TextEditingController controller;

  const _MetricInput({required this.metric, required this.controller});

  @override
  Widget build(BuildContext context) {
    final unit = (metric.unit ?? '').trim();
    final hint = metric.type == 'time' ? 'Ej: 5.42' : 'Ej: 52';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              metric.name,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              '${metric.key} • ${metric.direction == 'higher_is_better' ? '↑ mejor' : '↓ mejor'}'
              '${unit.isNotEmpty ? ' • $unit' : ''}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).textTheme.bodySmall?.color?.withOpacity(.7),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Valor',
                hintText: hint,
                border: const OutlineInputBorder(),
                suffixText: unit.isEmpty ? null : unit,
              ),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return null;
                final d = double.tryParse(t);
                if (d == null) return 'Número inválido';
                final min = metric.min;
                final max = metric.max;
                if (min != null && d < min) return 'Mín: $min';
                if (max != null && d > max) return 'Máx: $max';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            child,
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
