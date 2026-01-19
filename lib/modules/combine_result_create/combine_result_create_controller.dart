// lib/modules/combine/results/create/combine_result_create_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/combines/combine_metric.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import '../../../../core/network/api_repository.dart';

class CombineResultCreateController extends GetxController {
  final _api = Get.find<ApiRepository>();

  final formKey = GlobalKey<FormState>();

  final isLoading = false.obs;
  final isSaving = false.obs;
  final error = RxnString();

  // params
  int get eventId => int.tryParse(Get.parameters['eventId'] ?? '') ?? 0;

  // data
  final metrics = <CombineMetric>[].obs;
  final eventName = RxnString();

  // form fields
  final notesCtrl = TextEditingController();
  final overallScoreCtrl = TextEditingController();

  final measuredAt = Rxn<DateTime>();

  // valores dinámicos por métrica (key -> controller)
  final Map<String, TextEditingController> valueCtrls = {};

  final isLoadingPlayers = false.obs;
  final players = <Map<String, dynamic>>[].obs;
  final selectedPlayer = Rxn<Map<String, dynamic>>();

  // Para el Autocomplete
  late final TextEditingController playerSearchCtrl;
  final playerFieldKey = GlobalKey<FormFieldState>();

  late final FocusNode playerFocus;

  @override
  void onInit() {
    super.onInit();
    playerSearchCtrl = TextEditingController();
    playerFocus = FocusNode();

    measuredAt.value = DateTime.now();
    load();
    loadPlayers();
  }

  Future<void> loadPlayers() async {
    try {
      isLoadingPlayers.value = true;

      final categoryId = AppStorage.getSelectedCategoryId();

      final list = await _api.managerCategoryPlayers(categoryId!);
      players.assignAll(list);

      // si ya tenías uno seleccionado y sigue existiendo, mantenlo
      final currentId = selectedPlayer.value?['id'];
      if (currentId != null) {
        final found = players.firstWhereOrNull((p) => p['id'] == currentId);
        if (found != null) selectedPlayer.value = found;
      }
    } catch (_) {
      // no rompas UI
      players.clear();
      selectedPlayer.value = null;
    } finally {
      isLoadingPlayers.value = false;
    }
  }

  @override
  void onClose() {
    playerFocus.dispose();
    notesCtrl.dispose();
    overallScoreCtrl.dispose();
    for (final c in valueCtrls.values) {
      c.dispose();
    }
    super.onClose();
  }

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
      metrics.assignAll(detail.metrics.where((m) => (m.isActive ?? true)));

      // construir controllers por métrica
      for (final m in metrics) {
        valueCtrls.putIfAbsent(m.key, () => TextEditingController());
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
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

  double? _parseDouble(String s) {
    final v = double.tryParse(s.trim());
    return v;
  }

  int? _parseInt(String s) {
    final v = int.tryParse(s.trim());
    return (v != null && v > 0) ? v : null;
  }

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

    final dt = measuredAt.value ?? DateTime.now();

    // arma values[]
    final values = <Map<String, dynamic>>[];
    for (final m in metrics) {
      final ctrl = valueCtrls[m.key];
      if (ctrl == null) continue;

      final raw = ctrl.text.trim();
      if (raw.isEmpty) continue; // permite enviar parcial

      final num = double.tryParse(raw);
      if (num == null) {
        // si algún día soportas value_text, aquí lo mandas como texto
        error.value = 'Valor inválido en ${m.name}';
        return;
      }

      // respeta decimales si aplica
      final dec = (m.decimals ?? 0);
      final rounded = dec >= 0 ? double.parse(num.toStringAsFixed(dec)) : num;

      values.add({'key': m.key, 'value_number': rounded});
    }

    if (values.isEmpty) {
      error.value = 'Captura al menos una métrica.';
      return;
    }

    final overall = overallScoreCtrl.text.trim().isEmpty
        ? null
        : _parseDouble(overallScoreCtrl.text);

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
    // lowercase + remove accents common in ES
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
}
