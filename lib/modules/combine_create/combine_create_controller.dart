// lib/modules/combine/create/combine_create_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/category.dart';
import 'package:stopandgo/core/models/games.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import '../../../core/network/api_repository.dart';

class CombineCreateController extends GetxController {
  final _api = Get.find<ApiRepository>();

  final formKey = GlobalKey<FormState>();

  final isSaving = false.obs;
  final error = RxnString();

  final isLoadingCategories = false.obs;
  final categories = <Category>[].obs;
  final selectedCategory = Rxn<Category>();

  final isLoadingVenues = false.obs;
  final venues = <Venue>[].obs;
  final selectedVenue = Rxn<Venue>();

  final seasonIdCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  final startsAt = Rxn<DateTime>();
  final endsAt = Rxn<DateTime>();

  @override
  void onInit() {
    super.onInit();
    loadCategories();
    loadVenues();
  }

  Future<void> loadVenues() async {
    try {
      isLoadingVenues.value = true;
      error.value = null;

      final list = await _api.getVenues();
      venues.assignAll(list);

      if (venues.length == 1) {
        selectedVenue.value = venues.first;
      }
    } catch (_) {
      error.value = 'No se pudieron cargar sedes';
    } finally {
      isLoadingVenues.value = false;
    }
  }

  Future<void> loadCategories() async {
    try {
      isLoadingCategories.value = true;
      error.value = null;

      final list = await _api.getCoachCategories();
      categories.assignAll(list);

      // Si solo hay una, la seleccionamos automático
      if (categories.length == 1) {
        selectedCategory.value = categories.first;
      }
    } catch (e) {
      error.value = 'No se pudieron cargar categorías';
    } finally {
      isLoadingCategories.value = false;
    }
  }

  @override
  void onClose() {
    seasonIdCtrl.dispose();
    nameCtrl.dispose();
    notesCtrl.dispose();
    super.onClose();
  }

  int? _parseInt(String s) {
    final v = int.tryParse(s.trim());
    return (v != null && v > 0) ? v : null;
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

  Future<void> pickStartsAt(BuildContext context) async {
    final now = DateTime.now();
    final initial = startsAt.value ?? now;

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

    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    startsAt.value = dt;

    // si endsAt quedó antes, lo limpiamos
    if (endsAt.value != null && endsAt.value!.isBefore(dt)) {
      endsAt.value = null;
    }
  }

  Future<void> pickEndsAt(BuildContext context) async {
    final now = DateTime.now();
    final base = startsAt.value ?? now;
    final initial = endsAt.value ?? base.add(const Duration(hours: 2));

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

    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    // Validación: ends_at >= starts_at si ya hay starts
    if (startsAt.value != null && dt.isBefore(startsAt.value!)) {
      Get.snackbar('Fechas', 'La hora de fin debe ser posterior al inicio.');
      return;
    }

    endsAt.value = dt;
  }

  Future<void> submit() async {
    if (isSaving.value) return;

    error.value = null;

    final ok = formKey.currentState?.validate() ?? false;
    if (!ok) return;

    final seasonId = _parseInt(seasonIdCtrl.text);
    final venueId = selectedVenue.value?.id;

    final category = selectedCategory.value;
    if (category == null) {
      error.value = 'Selecciona una categoría.';
      return;
    }
    if (startsAt.value == null) {
      error.value = 'Selecciona fecha/hora de inicio.';
      return;
    }

    try {
      isSaving.value = true;
      final created = await _api.createCombineEvent(
        categoryId: category.id,
        seasonId: seasonId,
        venueId: venueId,
        name: nameCtrl.text.trim(),
        startsAt: _fmtDateTime(startsAt.value!),
        endsAt: endsAt.value != null ? _fmtDateTime(endsAt.value!) : null,
        notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
      );

      if (created == null) {
        error.value = 'No se pudo crear el evento.';
        return;
      }

      Get.back(result: created); // devuelve el evento creado
      Get.snackbar('Evaluación', 'Evento creado');
    } catch (e) {
      error.value = e.toString();
    } finally {
      isSaving.value = false;
    }
  }
}
