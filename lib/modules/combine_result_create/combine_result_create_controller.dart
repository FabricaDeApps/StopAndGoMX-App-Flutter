// lib/modules/combine/results/create/combine_result_create_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/combines/combine_metric.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/routes/app_routes.dart';
import '../../../../core/network/api_repository.dart';

class CombineResultCreateController extends GetxController {
  final _api = Get.find<ApiRepository>();

  final formKey = GlobalKey<FormState>();

  final isLoading = false.obs;
  final isSaving = false.obs;
  final error = RxnString();

  int get eventId => int.tryParse(Get.parameters['eventId'] ?? '') ?? 0;

  // data
  final metrics =
      <CombineMetric>[].obs; // métricas del evento (si las necesitas)
  final allMetrics = <CombineMetric>[].obs; // catálogo
  final eventName = RxnString();

  // selección (estable en GetX)
  final selectedMetricKeys = <String>[].obs;
  bool isMetricSelected(String key) => selectedMetricKeys.contains(key);

  // form fields
  final notesCtrl = TextEditingController();
  final overallScoreCtrl = TextEditingController();
  final measuredAt = Rxn<DateTime>();

  // valores dinámicos por métrica (key -> controller)
  final Map<String, TextEditingController> valueCtrls = {};

  // players
  final isLoadingPlayers = false.obs;
  final players = <Map<String, dynamic>>[].obs;
  final selectedPlayer = Rxn<Map<String, dynamic>>();

  late final TextEditingController playerSearchCtrl;
  final playerFieldKey = GlobalKey<FormFieldState>();
  late final FocusNode playerFocus;

  // Search dentro del picker
  final metricPickerSearch = ''.obs;

  @override
  void onInit() {
    super.onInit();
    playerSearchCtrl = TextEditingController();
    playerFocus = FocusNode();

    measuredAt.value = DateTime.now();
    load();
    loadPlayers();
    loadMetrics();
  }

  @override
  void onClose() {
    playerFocus.dispose();
    notesCtrl.dispose();
    overallScoreCtrl.dispose();
    playerSearchCtrl.dispose();

    // dispose controllers dinámicos
    for (final c in valueCtrls.values) {
      c.dispose();
    }
    super.onClose();
  }

  // -----------------------------
  // Loads
  // -----------------------------
  Future<void> load() async {
    try {
      isLoading.value = true;
      error.value = null;

      if (eventId <= 0) {
        error.value = 'Event inválido';
        return;
      }

      final detail = await _api.getCombineEventDetail(eventId: eventId);
      if (detail == null) {
        error.value = 'No se pudo cargar el detalle del evento';
        return;
      }

      eventName.value = detail.event.name;
      metrics.assignAll(detail.metrics.where((m) => m.isActive == true));
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadPlayers() async {
    try {
      isLoadingPlayers.value = true;

      final categoryId = AppStorage.getSelectedCategoryId();
      if (categoryId == null) {
        players.clear();
        selectedPlayer.value = null;
        return;
      }

      final list = await _api.managerCategoryPlayers(categoryId);
      players.assignAll(list);

      final currentId = selectedPlayer.value?['id'];
      if (currentId != null) {
        final found = players.firstWhereOrNull((p) => p['id'] == currentId);
        if (found != null) selectedPlayer.value = found;
      }
    } catch (_) {
      players.clear();
      selectedPlayer.value = null;
    } finally {
      isLoadingPlayers.value = false;
    }
  }

  Future<void> loadMetrics() async {
    try {
      isLoading.value = true;
      error.value = null;

      final list = await _api.getCombineMetrics(onlyActive: true);

      if (list == null) {
        allMetrics.clear();
        return;
      }

      final parsed = list.map((e) => CombineMetric.fromJson(e)).toList();
      allMetrics.assignAll(parsed);

      // default: selecciona todas al inicio (puedes cambiar a ninguna si prefieres)
      if (selectedMetricKeys.isEmpty) {
        selectedMetricKeys.assignAll(allMetrics.map((m) => m.key));
      }

      _syncValueControllers();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // -----------------------------
  // Selection helpers
  // -----------------------------
  List<CombineMetric> get selectedMetrics {
    final keys = selectedMetricKeys.toSet();
    return allMetrics.where((m) => keys.contains(m.key)).toList();
  }

  void setMetricSelected(String key, bool selected) {
    if (selected) {
      if (!selectedMetricKeys.contains(key)) selectedMetricKeys.add(key);
    } else {
      selectedMetricKeys.remove(key);
    }
    // 🔥 fuerza consistencia en overlays
    selectedMetricKeys.refresh();
    _syncValueControllers();
  }

  void selectAllMetrics() {
    selectedMetricKeys.assignAll(allMetrics.map((m) => m.key));
    selectedMetricKeys.refresh();

    _syncValueControllers();
  }

  void clearAllMetrics() {
    selectedMetricKeys.clear();
    selectedMetricKeys.refresh();

    _syncValueControllers();
  }

  void _syncValueControllers() {
    // crear controllers para seleccionadas
    for (final m in allMetrics) {
      if (selectedMetricKeys.contains(m.key) &&
          !valueCtrls.containsKey(m.key)) {
        valueCtrls[m.key] = TextEditingController();
      }
    }

    // remover controllers de NO seleccionadas
    final toRemove = valueCtrls.keys
        .where((k) => !selectedMetricKeys.contains(k))
        .toList();
    for (final k in toRemove) {
      valueCtrls[k]?.dispose();
      valueCtrls.remove(k);
    }
  }

  // -----------------------------
  // Picker UI
  // -----------------------------
  void openMetricPicker(BuildContext context) {
    final searchCtrl = TextEditingController();
    final tempSelected = selectedMetricKeys.toSet(); // estado local

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            List<CombineMetric> filtered() {
              final q = _norm(searchCtrl.text);
              if (q.isEmpty) return allMetrics.toList();
              return allMetrics.where((m) {
                final unit = (m.unit ?? '').trim();
                final hay = _norm(
                  '${m.name} ${m.key} $unit ${m.type} ${m.direction}',
                );
                return hay.contains(q);
              }).toList();
            }

            final list = filtered();

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.75,
              minChildSize: 0.45,
              maxChildSize: 0.95,
              builder: (context, scrollCtrl) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Elegir métricas (${tempSelected.length})',
                              style: Theme.of(ctx).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                tempSelected
                                  ..clear()
                                  ..addAll(allMetrics.map((m) => m.key));
                              });
                            },
                            child: const Text('Todas'),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() => tempSelected.clear());
                            },
                            child: const Text('Limpiar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      TextField(
                        controller: searchCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Buscar métrica',
                          hintText: 'Ej: salto, 40, tiempo…',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),

                      const SizedBox(height: 10),

                      Expanded(
                        child: list.isEmpty
                            ? const Center(
                                child: Text('No hay métricas que coincidan.'),
                              )
                            : ListView.separated(
                                controller: scrollCtrl,
                                itemCount: list.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (_, i) {
                                  final m = list[i];
                                  final selected = tempSelected.contains(m.key);
                                  final unit = (m.unit ?? '').trim();

                                  return CheckboxListTile(
                                    key: ValueKey('metric_${m.id}_${m.key}'),
                                    value: selected,
                                    onChanged: (v) {
                                      setState(() {
                                        final yes = v == true;
                                        if (yes) {
                                          tempSelected.add(m.key);
                                        } else {
                                          tempSelected.remove(m.key);
                                        }
                                      });
                                    },
                                    title: Text(
                                      m.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      '${m.key}'
                                      '${unit.isNotEmpty ? ' • $unit' : ''}'
                                      ' • ${m.type == 'time' ? 'Tiempo' : 'Número'}'
                                      ' • ${m.direction == 'higher_is_better' ? '↑ mejor' : '↓ mejor'}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                  );
                                },
                              ),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                // ✅ commit final al controller (esto sí usa GetX)
                                selectedMetricKeys.assignAll(
                                  tempSelected.toList(),
                                );
                                selectedMetricKeys.refresh();
                                _syncValueControllers();
                                Navigator.of(ctx).pop();
                              },
                              child: const Text('Aplicar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    ).whenComplete(() => searchCtrl.dispose());
  }

  // -----------------------------
  // Submit
  // -----------------------------
  Future<void> submit() async {
    if (isSaving.value) return;

    error.value = null;
    final ok = formKey.currentState?.validate() ?? false;
    if (!ok) return;

    final pid = selectedPlayerId();
    if (pid == null || pid <= 0) {
      error.value = 'Selecciona un jugador';
      return;
    }

    if (selectedMetricKeys.isEmpty) {
      error.value = 'Selecciona al menos una métrica.';
      return;
    }

    final dt = measuredAt.value ?? DateTime.now();

    final values = <Map<String, dynamic>>[];

    // ✅ usa seleccionadas, no metrics
    for (final m in selectedMetrics) {
      final ctrl = valueCtrls[m.key];
      if (ctrl == null) continue;

      final raw = ctrl.text.trim();
      if (raw.isEmpty) continue;

      final num = double.tryParse(raw);
      if (num == null) {
        error.value = 'Valor inválido en ${m.name}';
        return;
      }

      final dec = m.decimals;
      final rounded = dec >= 0 ? double.parse(num.toStringAsFixed(dec)) : num;

      values.add({'key': m.key, 'value_number': rounded});
    }

    if (values.isEmpty) {
      error.value = 'Captura al menos una métrica.';
      return;
    }

    final overall = overallScoreCtrl.text.trim().isEmpty
        ? null
        : double.tryParse(overallScoreCtrl.text.trim());

    try {
      isSaving.value = true;

      final res = await _api.createCombineResult(
        eventId: eventId,
        playerId: pid,
        measuredAt: _fmtDateTime(dt),
        notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
        overallScore: overall,
        values: values,
      );

      if (res == null) {
        error.value = 'No se pudo guardar el resultado';
        return;
      }

      Get.back(result: res);
      Get.snackbar('Evaluación', 'Resultado guardado');
    } catch (e) {
      error.value = e.toString();
    } finally {
      isSaving.value = false;
    }
  }

  // -----------------------------
  // Navigation
  // -----------------------------
  Future<void> goCreateMetric() async {
    final created = await Get.toNamed(Routes.combineCreateMetrics);
    if (created == null) return;

    // ✅ recarga catálogo, no solo evento
    await loadMetrics();

    if (created is CombineMetric) {
      setMetricSelected(created.key, true);
    }
  }

  // -----------------------------
  // Helpers
  // -----------------------------
  int? selectedPlayerId() {
    final id = selectedPlayer.value?['id'];
    if (id == null) return null;
    if (id is int) return id;
    return int.tryParse(id.toString());
  }

  String playerLabel(Map<String, dynamic> p) {
    final first = (p['first_name'] ?? '').toString().trim();
    final last = (p['last_name'] ?? '').toString().trim();
    final name = ('$first $last').trim();

    final jersey = p['jersey_number'];
    if (jersey != null && jersey.toString().isNotEmpty) {
      return name.isEmpty ? '#$jersey' : '$name  #$jersey';
    }
    return name.isEmpty ? 'Jugador #${p['id']}' : name;
  }

  String _norm(String s) {
    var t = s.toLowerCase().trim();
    const from = 'áéíóúüñ';
    const to = 'aeiouun';
    for (int i = 0; i < from.length; i++) {
      t = t.replaceAll(from[i], to[i]);
    }
    return t;
  }

  bool matchesPlayer(Map<String, dynamic> p, String query) {
    final q = _norm(query);
    if (q.isEmpty) return true;

    final id = (p['id'] ?? '').toString();
    final jersey = (p['jersey_number'] ?? '').toString();

    final first = (p['first_name'] ?? '').toString();
    final last = (p['last_name'] ?? '').toString();
    final full = ('$first $last').trim();

    final haystack = _norm('$full $first $last $id $jersey ${playerLabel(p)}');
    return haystack.contains(q);
  }

  String _fmtDateTime(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    final ss = d.second.toString().padLeft(2, '0');
    return '$y-$m-$day $hh:$mm:$ss';
  }

  Future<void> pickMeasuredAt(BuildContext context) async {
    final now = DateTime.now();
    final initial = measuredAt.value ?? now;

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;

    measuredAt.value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }
}
